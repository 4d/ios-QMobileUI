//
//  ActionManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import SwiftMessages
import Prephirences
import Eureka
import BrightFutures
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
public class ActionManager {

    /// Singleton for the app.
    public static let instance = ActionManager()

    /// Manage action one by one (see if we can parallelize later by group of concern)
    //public let operationQueue = OperationQueue(underlyingQueue: .background /*.userInitiated*/, maxConcurrentOperationCount: 1)

    /// List of requests
    public var requests: [ActionRequest] = []

    init() {
        setupDefaultHandler()
    }

    // MARK: handlers

    /// List of avaiable handlers
    public var handlers: [ActionResultHandler] = []

    fileprivate func setupDefaultHandler() { //swiftlint:disable:this function_body_length
        //swiftlint:disable:this function_body_length
        // default handlers

        // Show log
        append { result, _, _, _ in
            logger.debug("Action result \(result.json)")
            return true
        }

        // Show message as info message
        append { result, _, _, _ in
            guard let statusText = result.statusText else { return false }
            if result.success {
                SwiftMessages.info(statusText)
            } else {
                SwiftMessages.warning(statusText)
            }
            return true
        }

        // dataSynchro
        append { result, action, _, _ in
            guard result.dataSynchro else { return false }
            logger.info("Data synchronisation is launch after action \(action.name)")
            _ = dataSync { result in
                switch result {
                case .failure(let error):
                    logger.warning("Failed to do data synchro after action \(action.name): \(error)")
                case .success:
                    logger.info("Data synchro after action \(action.name) success")
                }
            }
            return true
        }

        // openURL
        append { result, _, _, _ in
            guard let urlString = result.openURL, let url = URL(string: urlString) else { return false }
            logger.info("Open url \(urlString)")
            onForeground {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if success {
                        logger.info("Open url \(urlString) done")
                    } else {
                        logger.warning("Failed to open url \(urlString)")
                    }
                })
            }
            return true
        }
        // Copy test to pasteboard
        append { result, _, _, _ in
            guard let pasteboard = result.pasteboard else { return false }
            UIPasteboard.general.string = pasteboard
            return true
        }
        append { result, _, _, _ in
            guard result.goBack else { return false }
            UIApplication.topViewController?.dismiss(animated: true, completion: {

            })

            return true
        }

        append { result, _, actionUI, context in
            guard let actionSheet = result.actionSheet else { return false }
            onForeground {
                let alertController = UIAlertController.build(from: actionSheet, context: context, handler: self.prepareAndExecuteAction)
                _ = alertController.checkPopUp(actionUI)
                alertController.show {

                }
            }
            return true
        }

        append { result, _, actionUI, context in
            guard let action = result.action else { return false }
            onForeground {
                self.prepareAndExecuteAction(action, actionUI, context)
            }
            return true
        }

        append { result, _, _, _ in
            guard let deepLink = result.deepLink else { return false }
            logger.info("Deeplink from action: \(deepLink)")
            foreground {
                ApplicationCoordinator.open(deepLink) { _ in }
            }
            return true
        }

        append { result, _, actionUI, _ in
            guard let share = result.share else { return false }
            let activityItems: [Any] = share.compactMap { item in
                if let itemInfo = item.dictionary, let value = itemInfo["value"] {
                    if let type = itemInfo["type"]?.string {
                        switch type {
                        case "url":
                            return URL(string: value.stringValue)
                        case "image":
                            if let url = URL(string: value.stringValue) {
                                if let data = try? Data(contentsOf: url) {
                                    return UIImage(data: data)
                                }
                                return url
                            }
                            return value.rawValue
                        default:
                            return value.rawValue
                        }
                    } else {
                        return value.rawValue
                    }
                } else {
                    return item.rawValue
                }
            }

            foreground {

                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                activityViewController.checkPopUp(actionUI)

                activityViewController.show(animated: true) {
                    logger.info("Share activity presented")
                }
            }

            return true
        }

        append { result, _, actionUI, _ in
            guard let urlString = result.downloadURL, let url = URL(string: urlString) else { return false }
            logger.info("Download url \(urlString)")

            AF.request(url).responseData { response in
                if let fileData = response.data {
                    foreground {
                        let activityViewController = UIActivityViewController(activityItems: [url.lastPathComponent, fileData], applicationActivities: nil)
                        activityViewController.checkPopUp(actionUI)
                        activityViewController.show(animated: true) {
                            logger.info("End to download \(url)")
                        }
                    }
                }
            }
            return true
        }

        onForeground {
            /// Code to inject custom handlers.
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

    typealias ActionExecutionCompletionHandler = ((Result<ActionResult, APIError>) -> Future<ActionResult, APIError>)
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

    // TODO remove ui and context?
    func executeActionRequest(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: ActionExecutionCompletionHandler?) {
        self.requests.append(request)
        let actionQueue: DispatchQueue = .background
        actionQueue.async {
            logger.info("Launch action \(request.action.name) with context and parameters: \(request.parameters)")
            request.lastDate = Date()
            _ = APIManager.instance.action(request, callbackQueue: .background) { (result) in
                self.onActionResult(request, actionUI, context, result, completionHandler)
            }
        }
    }

    func onActionResult(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ result: Result<ActionResult, APIError>, _ completionHandler: ActionExecutionCompletionHandler?) {
        request.result = result
        // Display result or do some actions (incremental etc...)
        switch result {
        case .failure(let error):
            logger.warning("Action error: \(error)")

            if !Prephirences.Auth.Login.form, error.isHTTPResponseWith(code: .unauthorized) {
                ApplicationAuthenticate.retryGuestLogin { authResult in
                    switch authResult {
                    case .success:
                        // XXX do not do infinite retry
                        self.executeActionRequest(request, actionUI, context, completionHandler)
                    case .failure(let authError):
                        self.showError(authError)
                       _ = completionHandler?(.failure(error))
                    }
                }
                return
            }
            self.showError(error)
            _ = completionHandler?(.failure(error))
        case .success(let value):
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
                }
            } else {
                onForeground {
                    background {
                        _ = self.handle(result: value, for: request.action, from: actionUI, in: context)
                    }
                }
            }
        }
    }

    /// Show error has status text.
    func showError(_ error: APIError) {
        logger.warning("Error when managing action response \(error.errorDescription ?? ""): \(error)")
        // Try to display the best error message...
        if let statusText = error.restErrors?.statusText { // dev message
            SwiftMessages.error(title: error.errorDescription ?? "", message: statusText)
        } else { /*if apiError.isRequestCase(.connectionLost) ||  apiError.isRequestCase(.notConnectedToInternet) {*/ // not working always
            if !ApplicationReachability.isReachable { // so check reachability status
                SwiftMessages.error(title: "", message: "Please check your network settings and data cover...") // CLEAN factorize with data sync error message...
            } else if case .sessionTaskFailed(let urlError) = error.afError {
                SwiftMessages.warning(urlError.localizedDescription)
            } else if let failureReason = error.failureReason {
                SwiftMessages.warning(failureReason)
            } else {
                SwiftMessages.error(title: error.errorDescription ?? "", message: "")
            }
        }
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

extension ActionResult {
    /// Return: `true` if a data synchronisation must be done after the action.
    fileprivate var dataSynchro: Bool {
        return json["dataSynchro"].boolValue
    }
    fileprivate var openURL: String? {
        return json["openURL"].string
    }
    fileprivate var downloadURL: String? {
         return json["downloadURL"].string
     }
    fileprivate var share: [JSON]? {
        return json["share"].array
    }
    fileprivate var pasteboard: String? {
        return json["pasteboard"].string
    }
    fileprivate var goTo: String? {
        return json["goTo"].string
    }
    fileprivate var goBack: Bool {
        return json["goBack"].boolValue
    }
    fileprivate var actionSheet: ActionSheet? {
        if json["actions"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return ActionSheet.decode(fromJSON: jsonString)
    }

    fileprivate var action: Action? {
        if json["parameters"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }
    /*fileprivate var action: Action? {
        guard let jsonString = json["action"].rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }*/

    fileprivate var deepLink: DeepLink? {
        return DeepLink.from(json)
    }

    typealias Validation = (String?, ValidationError)

    fileprivate var validationErrors: [Validation]? {
        guard let errors = json["validationErrors"].arrayObject else {
            return nil
        }

        return errors.compactMap { (object: Any) -> Validation? in
            if let message = object as? String {
                return (nil, ValidationError(msg: message))
            } else if let dictionary = object as? [String: String],
                let message = dictionary["message"],
                let field = dictionary["field"] {
                return (field, ValidationError(msg: message))
            }
            return nil
        }
    }
}
