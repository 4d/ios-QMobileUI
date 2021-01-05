//
//  ActionManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

import SwiftMessages
import Prephirences
import Eureka
import Combine
import Alamofire

import QMobileAPI

/// Class to execute actions and manage result.
///
/// # Workflow
///
/// An `Action` with context and user parameters are executed by requesting the server. This is the request.
///
/// Then when the server respond a result is decoded. According to result content, handlers could exectute code like login, show alert message, launch data synchro.
///
/// ## Customs action result handler
///
/// To inject custom action result handler you have two way. Make your `AppDelegate` implement `ActionResultHandler` or inject an app service which implement `ActionResultHandler`
///
public class ActionManager: NSObject, ObservableObject {

    /// Singleton for the app.
    public static let instance = ActionManager()

    /// Manage action one by one (see if we can parallelize later by group of concern)
    //public let operationQueue = OperationQueue(underlyingQueue: .background /*.userInitiated*/, maxConcurrentOperationCount: 1)

    /// List of requests
    @Published public var requests: [ActionRequest] = []

    /// Operation queue.
    fileprivate let queue = ActionRequestQueue()

    public var offlineAction: Bool = Prephirences.sharedInstance["action.offline"] as? Bool ?? false
    public var offlineActionHistoryMax: Int = Prephirences.sharedInstance["action.offline.history.max"] as? Int ?? 10

    private var bag = Set<AnyCancellable>()

    override init() {
        super.init()
        setupDefaultHandler()
        if offlineAction {
            initOfflineAction()
        }
    }

    fileprivate func initOfflineAction() {
        loadActionRequests()
        $requests.sink { [weak self] in
            print("new request \($0)")
            self?.saveActionRequests()
        }.store(in: &bag)
        registerListener()

        /*$requests.sink(receiveValue: { requests in
            print("\(requests.map({ $0.action.name }))")
           // self.queue.addRequests(requests) // each time so total , not by packet
        })
        .store(in: &subscriptions)*/
        /*requests.publisher.sink { completion in
            print("\(completion)")
        } receiveValue: { request in
            self.queue.addRequest(request)
        }.store(in: &bag)*/
    }

    // MARK: handlers

    /// List of avaiable handlers
    public var handlers: [ActionResultHandler] = []

    // MARK: - Action execution

    /// Execute the action or if there is at least one parameter show a form.
    public func prepareAndExecuteAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        if action.parameters.isEmpty {
            // Execute action without any parameters immedialtely
            executeAction(action, actionUI, context, nil /*without parameters*/, nil)
        } else {
            // Create UI according to action parameters
            var control: ActionParametersUIControl?
            if ActionFormSettings.alertIfOneField {
                control = UIAlertController.build(action, actionUI, context, self.executeActionUICallback) // could return nil if not managed
            }

            if control == nil {
                let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
                control = type.build(action, actionUI, context, self.executeActionUICallback)
            }
            control?.showActionParameters()
        }
    }

    typealias ActionExecutionCompletionHandler = ((Result<ActionResult, ActionRequest.Error>) -> Future<ActionResult, ActionRequest.Error>)
    typealias ActionExecutionContext = (Action, ActionUI, ActionContext, ActionParameters?, ActionExecutionCompletionHandler?)

    /// Execute action if success (ie. no error in form validatiion
    func executeActionUICallback(_ result: Result<ActionExecutionContext, ActionParametersUIError>) {
        switch result {
        case .success(let context):
            executeAction(context.0, context.1, context.2, context.3, context.4)
        case .failure(let error):
            if error.isUserRequested {
                logger.info("Action not performed: \(error)") // cancel
            } else {
                logger.warning("Action not performed: \(error)")
            }
        }
    }

    /// Execute the network call for action.
    func executeAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionParameters: ActionParameters?, _ completionHandler: ActionExecutionCompletionHandler?) {

        let contextParameters: ActionParameters? = context.actionContextParameters()
        let request = action.newRequest(actionParameters: actionParameters, contextParameters: contextParameters)
        executeActionRequest(request, actionUI, context, completionHandler)
    }

    func openUI(_ request: ActionRequest, _ actionUI: ActionUI) {
        let action = request.action
        if action.parameters.isEmpty {
            return
        }
        let context = request
        // Create UI according to action parameters
        var control: ActionParametersUIControl?
        if ActionFormSettings.alertIfOneField {
            control = UIAlertController.build(action, actionUI, context, self.executeActionUICallback) // could return nil if not managed
        }

        if control == nil {
            let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
            control = type.build(action, actionUI, context, self.executeActionUICallback)
        }
        control?.showActionParameters()
    }

    func loadActionRequests() {
        let store: PreferencesType = Prephirences.sharedInstance
        do {
            if let requests: [ActionRequest] = try store.decodable([ActionRequest].self, forKey: "action.requests") {
                for request in requests {
                    self.requests.append(request)

                    //self.queue.addRequest(request, request, )
                }
            }
            checkHistory()
        } catch {
            logger.warning("Failed to load actions history and draft \(error)")
            // TODO check if must relaunch?
        }
    }

    func checkHistory() {

        // TODO remove from requests older requests if finished and more than offlineActionHistoryMax
    }

    func saveActionRequests() {
        // if possible call it when list published change (and any element)
        let store: MutablePreferencesType? = Prephirences.sharedMutableInstance
        do {
            try store?.set(encodable: self.requests, forKey: "action.requests")
        } catch {
            logger.warning("Failed to save actions history and draft \(error)")
        }
    }

    // TODO remove ui and context?
    func executeActionRequest(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: ActionExecutionCompletionHandler?) {

        if offlineAction {
            request.state = .ready
            self.requests.append(request)
            self.queue.addRequest(request, actionUI, context, completionHandler)
        } else {
            let actionQueue: DispatchQueue = .background
            actionQueue.async {
                logger.info("Launch action \(request.action.name) with context and parameters: \(request.parameters)")
                request.state = .executing
                request.lastDate = Date()
                _ = APIManager.instance.action(request, callbackQueue: .background) { (result) in
                    self.onActionResult(request, actionUI, context, result.mapError { ActionRequest.Error($0) }, completionHandler)
                }
            }
        }
    }

    fileprivate func onOfflineActionResult(_ result: Result<ActionResult, ActionRequest.Error>, _ request: ActionRequest, _ completionHandler: ActionManager.ActionExecutionCompletionHandler?, _ actionUI: ActionUI, _ context: ActionContext) {
        saveActionRequests() // TODO check if sink call on element change?
        // Display result or do some actions (incremental etc...)
        switch result {
        case .failure(let error):
            logger.warning("Action error: \(error)")

            // tempo code to see diff between task to relaunch or not
            if error.mustRetry {
                request.state = .pending
            } else {
                request.state = .finished // with error
            }

            _ = completionHandler?(.failure(error))
        case .success(let value):
            request.state = .finished
            logger.debug("\(value)")
            if let completionHandler = completionHandler {
                let future = completionHandler(.success(value))
                // delay handle action result, after form finish with it
                future.onComplete { result in
                    onForeground {
                        background {
                            _ = self.handle(result: value, for: request.action, from: actionUI, in: context)
                        }
                    }
                }.sink()
                .store(in: &self.bag)
            } else {
                onForeground {
                    background {
                        _ = self.handle(result: value, for: request.action, from: actionUI, in: context)
                    }
                }
            }
        }
    }

    func onActionResult(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ result: Result<ActionResult, ActionRequest.Error>, _ completionHandler: ActionExecutionCompletionHandler?) {
        request.result = result

        if offlineAction {
            onOfflineActionResult(result, request, completionHandler, actionUI, context)
        } else {
            // Display result or do some actions (incremental etc...)
            switch result {
            case .failure(let error):
                logger.warning("Action error: \(error)")

                if !Prephirences.Auth.Login.form, error.isUnauthorized {
                    ApplicationAuthenticate.retryGuestLogin { authResult in
                        switch authResult {
                        case .success:
                            // XXX do not do infinite retry
                            self.executeActionRequest(request, actionUI, context, completionHandler)
                        case .failure(let authError):
                            SwiftMessages.showError(ActionRequest.Error(authError))
                            _ = completionHandler?(.failure(error))
                        }
                    }
                    return
                }
                // tempo code to see diff between task to relaunch or not
                if error.mustRetry {
                    request.state = .pending
                } else {
                    request.state = .finished // with error
                }

                SwiftMessages.showError(error)
                _ = completionHandler?(.failure(error))
            case .success(let value):
                request.state = .finished
                logger.debug("\(value)")
                if let completionHandler = completionHandler {
                    let future = completionHandler(.success(value))
                    // delay handle action result, after form finish with it
                    future.onComplete { result in
                        onForeground {
                            background {
                                _ = self.handle(result: value, for: request.action, from: actionUI, in: context)
                            }
                        }
                    }.sink()
                    .store(in: &self.bag)
                } else {
                    onForeground {
                        background {
                            _ = self.handle(result: value, for: request.action, from: actionUI, in: context)
                        }
                    }
                }
            }
        }
    }

    // MARK: - queue based

    fileprivate var isSuspended: Bool {
        get {
            return self.queue.isSuspended
        }
        set {
            self.queue.isSuspended = newValue
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    fileprivate func waitUntilAllOperationsAreFinished() {
        self.queue.waitUntilAllOperationsAreFinished()
    }
}

extension SwiftMessages {

    static func showError(_ error: ActionRequest.Error) {
        logger.warning("Error when managing action response \(error.errorDescription): \(error)")
        // Try to display the best error message...
        if let statusText = error.statusText { // dev message
            SwiftMessages.error(title: error.errorDescription, message: statusText)
        } else { /*if apiError.isRequestCase(.connectionLost) ||  apiError.isRequestCase(.notConnectedToInternet) {*/ // not working always
            if !ApplicationReachability.isReachable { // so check reachability status
                SwiftMessages.error(title: "", message: "Please check your network settings and data cover...") // CLEAN factorize with data sync error message...
            } else if let failureReason = error.failureReason {
                SwiftMessages.warning(failureReason)
            } else {
                SwiftMessages.error(title: error.errorDescription, message: "")
            }
        }
    }
}

// MARK: manage reachability to suspend operation

extension ActionManager: ReachabilityListener, StatusListener {

    fileprivate func registerListener() {
        ApplicationReachability.instance.add(listener: self)
    }

    public func onReachabilityChanged(status: NetworkReachabilityStatus, old: NetworkReachabilityStatus) {
        checkSuspend()
    }

    public func onStatusChanged(status: Status, old: Status) {
        checkSuspend()
    }

    fileprivate func checkSuspend() {
        let serverStatus = ApplicationReachability.instance.serverStatus
        // could have other criteria like manual pause or ???
        self.isSuspended = !serverStatus.ok

    }
}

// Implement context to be able to reopen UI with data from request
extension ActionRequest: ActionContext {

    public func actionContextParameters() -> ActionParameters? {
        return self.contextParameters // a copy of original context parameter
    }

    public func actionParameterValue(for field: String) -> Any? {
        return self.actionParameters?[field] // this context will return parameter form already filled by user, it do not have record to complete more field
    }

}

// MARK: ActionResultHandler

extension ActionManager: ActionResultHandler {

    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        var handled = false
        for handler in handlers {
            handled = handler.handle(result: result, for: action, from: actionUI, in: context) || handled
        }
        return handled
    }

    fileprivate func setupDefaultHandler() {
        // default handlers

        // Show debug log for each action result
        append { result, _, _, _ in
            logger.debug("Action result \(result.json)")
            return true
        }

        append(ActionResult.statusTextBlock)
        append(ActionResult.dataSynchroBlock)
        append(ActionResult.openURLBlock)
        append(ActionResult.pasteboardBlock)
        append(ActionResult.actionSheetBlock(self.prepareAndExecuteAction))
        append(ActionResult.actionBlock(self.prepareAndExecuteAction))
        append(ActionResult.deepLinkBlock)
        append(ActionResult.shareBlock)
        append(ActionResult.downloadURLBlock)

        onForeground {
            // Code to inject custom handlers.
            if let injectedHandler = UIApplication.shared.delegate as? ActionResultHandler {
                self.handlers.append(injectedHandler)
            }
            if let app = UIApplication.shared as? QApplication {
                for service in app.services.services {
                    if let injectedHandler = service as? ActionResultHandler {
                        self.handlers.append(injectedHandler)
                    }
                }
            }
        }
    }

    public func append(_ block: @escaping ActionResultHandler.Block) {
        handlers.append(ActionResultHandlerBlock(block))
    }

    public func append(_ handler: ActionResultHandler) {
        handlers.append(handler)
    }
}

/// Handle an action results.
public protocol ActionResultHandler {
    typealias Block = (ActionResult, Action, ActionUI, ActionContext) -> Bool
    func handle(result: ActionResult, for action: Action, from: ActionUI, in context: ActionContext) -> Bool
}

/// Handle action result with a block
public struct ActionResultHandlerBlock: ActionResultHandler {
    var block: ActionResultHandler.Block
    public init(_ block: @escaping ActionResultHandler.Block) {
        self.block = block
    }
    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        return block(result, action, actionUI, context)
    }
}

class ActionOperation: Operation {
    var actionRequest: ActionRequest
    init(_ actionRequest: ActionRequest) {
        self.actionRequest = actionRequest
    }

    override func main () {

    }
}
