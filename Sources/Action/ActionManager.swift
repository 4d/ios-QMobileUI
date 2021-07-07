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
import QMobileDataSync

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
    // public let operationQueue = OperationQueue(underlyingQueue: .background /*.userInitiated*/, maxConcurrentOperationCount: 1)

    /// List of requests
    @Published public var requests: [ActionRequest] = []

    /// Operation queue.
    fileprivate let queue = ActionRequestQueue()

    public let hasAction: Bool = Prephirences.sharedInstance["action"] as? Bool ?? true
    public let offlineAction: Bool = Prephirences.sharedInstance["action.offline"] as? Bool ?? true // FEATURE #112750
    public let offlineActionHistoryMax: Int = Prephirences.sharedInstance["action.offline.history.max"] as? Int ?? 10
    public let editRejectedAction: Bool = Prephirences.sharedInstance["action.rejectedEdit"] as? Bool ?? true // FEATURE #125025
    public static let customFormat: Bool = Prephirences.sharedInstance["action.customFormat"] as? Bool ?? true // FEATURE ##128195

    let cache = ActionManagerCache()

    private var bag = Set<AnyCancellable>()

    override init() {
        super.init()
        setupDefaultHandler()
        if offlineAction {
            initOfflineAction()
        }
        logger.debug("Feature offline action \(offlineAction ? "activated": "deactivated")")
        logger.debug("Feature edit rejected action \(editRejectedAction ? "activated": "deactivated")")
    }

    fileprivate func initOfflineAction() {
        loadActionRequests()

        $requests.sink { [weak self] requests in
            if !requests.isEmpty {
                logger.debug("New action request \(String(describing: requests.last))")
                self?.saveActionRequests(requests)
            }
        }.store(in: &bag)
        registerListener()
    }

    func sendChange() {
        self.saveActionRequests()
        foreground {
            self.objectWillChange.send()
        }
    }
    // MARK: handlers

    /// List of avaiable handlers
    var handlers: [ActionResultHandler] = []

    // MARK: - Action execution

    /// Execute the action or if there is at least one parameter show a form.
    public func prepareAndExecuteAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        if action.preset == .sort {
            // local action without server
            guard let tableName = context.actionContextParameters()?[ActionParametersKey.table] as? String else {
                logger.warning("Cannot sort without table name \(action)")
                return
            }
            guard let tableInfo = ApplicationDataSync.instance.dataSync.dataStore.tableInfo(forOriginalName: tableName) else {
                logger.warning("Cannot find table info for \(tableName) to sort")
                return
            }
            
            guard let sortDescriptors = action.parameters?.compactMap({ $0.sortDescriptor(tableInfo: tableInfo) }), !sortDescriptors.isEmpty else { return }

            // Not clean way to get list form, maybe context could provide the "DataSource"
            guard let dataSourceSortable = ((context as? UIView)?.owningViewController?.firstController as? DataSourceSortable) else {
                logger.warning("Cound not find dataSource to apply sort action \(action)")
                return
            }
            dataSourceSortable.setSortDescriptors(sortDescriptors)
        } else if action.parameters.isEmpty {
            // Execute action without any parameters immedialtely
            executeAction(action, ActionRequest.generateID(action), actionUI, context, nil /*without parameters*/, Just(()).eraseToAnyPublisher(), nil)
        } else {
            // Create UI according to action parameters
            var control: ActionParametersUIControl?
            if ActionFormSettings.alertIfOneField {
                control = UIAlertController.build(action, actionUI, context, self) // could return nil if not managed
            }

            if control == nil {
                let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
                control = type.build(action, actionUI, context, self)
            }
            if let control = control {
                control.showActionParameters()
            } else {
                logger.debug("Failed to build action for \(action)")
            }
        }
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
            control = UIAlertController.build(action, actionUI, context, self) // could return nil if not managed
        }

        if control == nil {
            let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
            control = type.build(action, actionUI, context, self)
        }
        control?.showActionParameters()
    }

    func loadActionRequests() {
        let store: PreferencesType = Prephirences.sharedInstance
        do {
            if let requests: [ActionRequest] = try store.decodable([ActionRequest].self, forKey: "action.requests") {
                self.requests.append(contentsOf: requests)
                for request in requests where !request.state.isFinal && !request.action.isOnlineOnly {
                        let noWait: ActionExecutor.WaitPresenter = Just<Void>(()).eraseToAnyPublisher()
                        self.queue.addRequest(request, BackgroundActionUI(), request, noWait) { result in
                            switch result {
                            case .success(let result):
                                logger.debug("Background action \(request) finish with result \(result)")
                            case .failure(let error):
                                logger.warning("Background action \(request) finish with error \(error)")
                            }
                            DispatchQueue.main.async {
                                self.objectWillChange.send()
                            }
                        }
                }
            }
            checkHistory()
        } catch {
            logger.warning("Failed to load actions history and draft \(error)")
            // TODO check if must relaunch?
        }
    }

    func checkHistory() {
        var finished = 0
        var toRemoves: [Int] = []
        for (index, request) in requests.enumerated() where request.state == .cancelled {
            toRemoves.append(index)
        }
        for (index, request) in requests.enumerated().reversed() /* old at the begining */ where request.state == .completed {
            finished += 1
            if finished > offlineActionHistoryMax {
                toRemoves.append(index)
            }
        }
        for toRemove in toRemoves where toRemove < requests.count {
            requests.remove(at: toRemove)
        }
    }

    func saveActionRequests(_ requests: [ActionRequest]? = nil) {
        // if possible call it when list published change (and any element)
        let store: MutablePreferencesType? = Prephirences.sharedMutableInstance
        do {
            try store?.set(encodable: requests ?? self.requests, forKey: "action.requests")
        } catch {
            logger.warning("Failed to save actions history and draft \(error)")
        }
    }

    /// Manage result of action immedately, without retry
    fileprivate func onActionResult(_ request: ActionRequest, // swiftlint:disable:this function_parameter_count
                                    _ actionUI: ActionUI,
                                    _ context: ActionContext,
                                    _ waitPresenter: ActionExecutor.WaitPresenter,
                                    _ result: Result<ActionResult, ActionRequest.Error>,
                                    _ completionHandler: ActionExecutor.CompletionHandler?) {
        request.result = result
        assert(request.action.isOnlineOnly)
        // Display result or do some actions (incremental etc...)
        switch result {
        case .failure(let error):
            logger.warning("Action error: \(error)")

            if !Prephirences.Auth.Login.form, error.isUnauthorized {
                request.tryCount += 1
                ApplicationAuthenticate.retryGuestLogin { authResult in
                    switch authResult {
                    case .success:
                        if request.tryCount < 5 { // do not do infinite retry
                            self.executeActionOnlineOnly(request, actionUI, context, waitPresenter, completionHandler)
                        } else {
                            // must not occurs, if auth result, then we must not be unauthorized
                            request.state = .completed
                            _ = completionHandler?(.failure(error))
                        }
                    case .failure(let authError):
                        request.state = .completed
                        SwiftMessages.showError(ActionRequest.Error(authError))
                        _ = completionHandler?(.failure(error))
                    }
                }
                sendChange()
                return
            }
            request.state = .completed
            SwiftMessages.showError(error)
            sendChange()
            _ = completionHandler?(.failure(error))
        case .success(let value):
            request.state = .completed
            sendChange()
            logger.debug("\(value)")
            if let completionHandler = completionHandler {
                /*let waitPresenter = */completionHandler(.success(value))
                // delay handle action result, after form finish with it
                waitPresenter.onComplete { _ in
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

    func willRefresh() {
        logger.verbose("SignIn:\(APIManager.isSignIn), hasLogin:\(ApplicationAuthenticate.hasLogin) ")
        if !APIManager.isSignIn && !ApplicationAuthenticate.hasLogin {
            ApplicationAuthenticate.retryGuestLogin { authResult in
                ServerStatusManager.instance.checkStatus()
                if case .failure(let error) = authResult {
                    ActionManager.instance.checkSuspend()
                    DispatchQueue.main.async {
                        logger.warning("Authentication failure.\n\(error.restErrors?.statusText ?? error.localizedDescription)")
                        SwiftMessages.warning("Authentication failure.\n\(error.restErrors?.statusText ?? error.localizedDescription)") { (_, config) in
                            var config = config
                            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
                            return config
                        }
                    }
                }
            }
        }
        ServerStatusManager.instance.checkStatus()
    }

    // MARK: - queue based
    var pause: Bool = false {
        didSet {
            logger.debug("Action queue is \(pause ? "paused": "started")")
            checkSuspend()
        }
    }
    var isServerAccessibleCache: Bool = false
    var isServerAccessible: Bool {
        let serverStatus = ApplicationReachability.instance.serverStatus
        if serverStatus != .checking {
            isServerAccessibleCache = serverStatus.isSuccess
        }
        return isServerAccessibleCache
    }

    private(set) var isSuspended: Bool {
        get {
            return self.queue.isSuspended
        }
        set {
            self.queue.isSuspended = newValue
            DispatchQueue.main.after(1) {
                self.objectWillChange.send()
            }
        }
    }

    fileprivate func waitUntilAllOperationsAreFinished() {
        self.queue.waitUntilAllOperationsAreFinished()
    }

    func requestUpdated(_ request: ActionRequest) {
        if editRejectedAction {
            if request.isFailure {
                self.requests.removeAll(where: { $0.id == request.id })
                DispatchQueue.main.async { // TODO maybe wait queue is reactivated, and ui closed
                    logger.info("new action start \(request.action)")
                    let newRequest = ActionRequest(
                        action: request.action,
                        actionParameters: request.actionParameters,
                        contextParameters: request.contextParameters,
                        id: ActionRequest.generateID(request.action),
                        state: nil,
                        result: nil)

                    let noWait: ActionExecutor.WaitPresenter = Just<Void>(()).eraseToAnyPublisher()
                    self.executeActionRequest(newRequest, actionUI: BackgroundActionUI(), context: newRequest, waitPresenter: noWait) { result in
                        logger.info("new action end \(result)")
                    }
                }
            } else {
                self.queue.requestUpdated(request)
            }
        } else {
            self.queue.requestUpdated(request)
        }
        self.sendChange()
    }

}

// MARK: - Image

extension APIManager {

    func uploadImage(url: URL?, image: UIImage, completion imageCompletion: @escaping APIManager.CompletionUploadResultHandler) {
        if let url = url {
            logger.debug("Upload image using url \(url)")
            _ = upload(url: url, completionHandler: imageCompletion)
        } else if let imageData = image.jpegData(compressionQuality: 1) {
            logger.debug("Upload image using jpegData")
            _ = upload(data: imageData, image: true, mimeType: "image/jpeg", completionHandler: imageCompletion)
        } else if let imageData = image.pngData() {
            logger.debug("Upload image using pngData")
            _ = upload(data: imageData, image: true, mimeType: "image/png", completionHandler: imageCompletion)
        } else {
            assertionFailure("Cannot convert row data to upload")
            imageCompletion(.failure(.request(NSError(domain: "assert", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot upload unknow data type"])))) // Not convertible, must not corrurs, just create wrong error
        }
    }
}

// MARK: - ActionExecutor

/// Responsible of executing an action
protocol ActionExecutor {
    typealias WaitPresenter = AnyPublisher<Void, Never>
    typealias CompletionHandler = (Result<ActionResult, ActionRequest.Error>) -> Void
    typealias Context = (Action, ActionUI, ActionContext, ActionParameters?, ActionExecutor.WaitPresenter, ActionExecutor.CompletionHandler?)

    func executeAction(_ action: Action, // swiftlint:disable:this function_parameter_count
                       _ id: String, // swiftlint:disable:this identifier_name
                       _ actionUI: ActionUI,
                       _ context: ActionContext,
                       _ actionParameters: ActionParameters?,
                       _ waitPresenter: ActionExecutor.WaitPresenter,
                       _ completionHandler: ActionExecutor.CompletionHandler?)
}

extension ActionExecutor {

    /// Execute action if success (ie. no error in form validation
    @available(*, deprecated, message: "use executeAction(_,_,_,_,_)")
    func executeAction(_ context: ActionExecutor.Context) {
        executeAction(context.0, ActionRequest.generateID(context.0), context.1, context.2, context.3, context.4, context.5)
    }

}

extension ActionManager: ActionExecutor {

    /// Execute the network call for action.
    func executeAction(_ action: Action, // swiftlint:disable:this function_parameter_count
                       _ id: String, // swiftlint:disable:this identifier_name
                       _ actionUI: ActionUI,
                       _ context: ActionContext,
                       _ actionParameters: ActionParameters?,
                       _ waitPresenter: ActionExecutor.WaitPresenter,
                       _ completionHandler: ActionExecutor.CompletionHandler?) {

        // Create the action request
        let contextParameters: ActionParameters? = context.actionContextParameters()
        let request = action.newRequest(actionParameters: actionParameters, contextParameters: contextParameters, id: id)

        // and execute it
        executeActionRequest(request, actionUI: actionUI, context: context, waitPresenter: waitPresenter, completionHandler)
    }

    fileprivate func executeActionOnlineOnly(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ waitPresenter: ActionExecutor.WaitPresenter, _ completionHandler: ((Result<ActionResult, ActionRequest.Error>) -> Void)?) {

        let actionQueue: DispatchQueue = .background
        actionQueue.async {
            logger.info("Launch action \(request.action.name) with context and parameters: \(request.parameters)")
            request.state = .executing
            _ = APIManager.instance.action(request, callbackQueue: .background) { result in
                request.lastDate = Date()
                self.onActionResult(request, actionUI, context, waitPresenter, result.mapError { ActionRequest.Error($0) }, completionHandler)
            }
        }
    }

    /// Execute an action request.
    ///
    /// Use at your own risk, it could change!
    /// - Parameters:
    ///   - request: the request to execute
    ///   - actionUI: the origin ui element that produce the request. If none will be replaced by a mock object. This element provide graphic context.
    ///   - context: the data context, allow to get some context values, default values etc.. but request must have already filled with it
    ///   - waitPresenter: you could pass a wait presenter to wait on yout UI (if you want to close your UI for instance) before the managing of action results (ie. show statusText, do synchro)
    ///   - completionHandler: receive result of the action.
    public func executeActionRequest(_ request: ActionRequest,
                                     actionUI: ActionUI = BackgroundActionUI.instance,
                                     context: ActionContext? = nil,
                                     waitPresenter: /*ActionExecutor.WaitPresenter*/ AnyPublisher<Void, Never>,
                                     _ completionHandler: ((Result<ActionResult, ActionRequest.Error>) -> Void)? = nil) {
        request.state = .ready

        self.requests.append(request)
        if offlineAction && !request.action.isOnlineOnly {
            self.queue.addRequest(request, actionUI, context ?? request, waitPresenter) { result in
                completionHandler?(result)
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            self.objectWillChange.send()
        } else {
            executeActionOnlineOnly(request, actionUI, context ?? request, waitPresenter, completionHandler)
        }
    }

    /// Cancel the request
    func remove(_ request: ActionRequest) {
        /*REMOVE instead of CANCEL ? self.requests.removeAll { request in
         return request == operation // (if request without id, it could failed)
         }*/
        request.state = .cancelled
        guard let requestOp = self.queue.operations.first(where: { oneOp -> Bool in
            guard let requestOp = oneOp as? ActionRequestOperation else {
                return false
            }
            return requestOp.request == request
        }) as? ActionRequestOperation else {
            return
        }
        remove(requestOp)
        saveActionRequests()
        sendChange()
    }

    /// Remove an operation ie. remove from list and cancel it
    fileprivate func remove(_ operation: ActionRequestOperation) {
        _ = self.queue.remove(operation) // cancel
    }
}

/// Execute the network call for action.

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

extension ActionManager: ReachabilityListener, ServerStatusListener, AuthenticateListener {

    fileprivate func registerListener() {
        ApplicationReachability.instance.add(listener: self)
        ApplicationAuthenticate.instance.add(listener: self)
    }

    public func onReachabilityChanged(status: NetworkReachabilityStatus, old: NetworkReachabilityStatus) {
        checkSuspend()
    }

    public func onServerStatusChanged(status: ServerStatus, old: ServerStatus) {
        checkSuspend()
    }

    public func didLogin(result: Result<AuthToken, APIError>) -> Bool {
        checkSuspend()
        return false
    }

    public func didLogout() {
        checkSuspend()
    }

    func checkSuspend() {
        let serverStatus = ApplicationReachability.instance.serverStatus
        // could have other criteria like manual pause or ???
        self.isSuspended = !serverStatus.isSuccess || pause || !APIManager.isSignIn
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

class ActionOperation: Operation {
    var actionRequest: ActionRequest
    init(_ actionRequest: ActionRequest) {
        self.actionRequest = actionRequest
    }

    override func main () {

    }
}

// placeholder for UI elements if no more element
// Handlers use it mainly to present new elements, maybe remove that!
public struct BackgroundActionUI: ActionUI {
    public static var instance: ActionUI { BackgroundActionUI() }
    public static func build(from action: Action, context: ActionContext, handler: @escaping Handler) -> ActionUI {
        // maybe object must allow to repopen a new dialog using actionmanager
        return BackgroundActionUI()
    }
}
import QMobileDataStore

extension ActionParameter {
    func sortDescriptor(tableInfo: DataStoreTableInfo) -> NSSortDescriptor? {
        if let fieldInfo = tableInfo.fieldInfo(for: self.defaultField ?? self.name) {
            return fieldInfo.sortDescriptor(ascending: self.format == nil || self.format == .custom("ascending"))
        }
        return nil
    }
}
