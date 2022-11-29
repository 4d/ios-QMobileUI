//
//  ActionRequestOperation.swift
//  QMobileUI
//
//  Created by phimage on 05/11/2020.
//

import Foundation

import QMobileAPI
import Moya
import Prephirences
import SwiftMessages

import Combine

class ActionRequestOperation: AsynchronousResultOperation<ActionResult, ActionRequest.Error> {

    weak var nextOperation: Operation?

    var request: ActionRequest

    var actionUI: ActionUI
    var context: ActionContext
    var waitUI: ActionExecutor.WaitPresenter
    var completionHandler: ActionExecutor.CompletionHandler?

    private var bag = Set<AnyCancellable>()

    init(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ waitUI: ActionExecutor.WaitPresenter, _ completionHandler: ActionExecutor.CompletionHandler?) {
        self.request = request
        self.actionUI = actionUI
        self.context = context
        self.waitUI = waitUI
        self.completionHandler = completionHandler

        super.init()
        self.name = self.request.id + self.request.action.name

        self.onResult = { result in
            self.request.result = result
            ActionManager.instance.sendChange()

            switch result {
            case .success(let value):
                // logger.error("Action result not managed yet")

                let handle: () -> Void = {
                    onForeground {
                        background {
                            _ =  ActionManager.instance.handle(result: value, for: request.action, from: actionUI, in: context)
                        }
                    }
                }
                if value.success {
                    request.clean()
                }
                completionHandler?(.success(value)) // close UI or display some info
                // delay handle action result, after form finish with it
                waitUI.onComplete { _ in
                    handle()
                }.sink().store(in: &self.bag)

            case .failure(let error):
                completionHandler?(result)
                logger.warning("Error on action request operation \(error)")
            }
        }

        self.onStateChanged = { _ in
            ActionManager.instance.sendChange()
        }

        // test or notify block
        #if DEBUG
        if logger.isEnabledFor(level: .verbose) {
            self.completionBlock = { // default qos, not sync with queue
                if let result = self.request.result {
                    switch result {
                    case .success(let actionResult):
                        logger.verbose("✅ \(actionResult.statusText ?? "EMPTY") for operation \(self.request.action.name)")
                    case .failure(let error):
                        logger.verbose("🔴 \(error) for operation \(self.request.action.name)")
                    }
                }
            }
        }
        #endif
    }

    override final func addDependency(_ operation: Operation) {
        super.addDependency(operation)
        if let previousOperation = operation as? ActionRequestOperation {
            previousOperation.nextOperation = self
        }
    }

    enum RetryMode {
        case /*dispatch, */operation/*, combine*/
    }

    var retryMode: RetryMode = .operation

    private func retry(with result: Result<ActionResult, ActionRequest.Error>, on queue: ActionRequestQueue) {
        self.request.result = result
        switch self.retryMode {
        /*case .dispatch:
         self.request.result = result
         self.main()*/
        case .operation:
            queue.retry(self)
            self.finish(with: result)
        }
    }

    private func complete(with result: Result<ActionResult, ActionRequest.Error>, on queue: ActionRequestQueue) {
        switch result {
        case .success:
            request.state = .completed
            request.lastDate = Date()
            self.finish(with: result)
        case .failure(let error):
            guard error.mustRetry else {
                request.state = .completed
                request.lastDate = Date()
                self.finish(with: result) // finish with error such as remote server user error
                return
            }
            logger.warning("retry: \(self.request)")

            if error.isUnauthorized {
                if Prephirences.Auth.Login.form {
                    ApplicationCoordinator.logout()
                    SwiftMessages.warning("Authentication failure.\n\(error.restErrors?.statusText ?? error.localizedDescription)")
                } else if error.isNoLicences {
                    ApplicationAuthenticate.showGuestNolicenses()
                } else {
                    ApplicationAuthenticate.retryGuestLogin { authResult in
                        // XXX maybe if failure pause the queue... do not retry for nothing... but this is a weird situation
                        if case .failure(let error) = authResult {
                            ActionManager.instance.checkSuspend() // XXX maybe instead actionmanager must listen to login/logout
                            /*SwiftMessages.warning*/logger.warning("Authentication failure.\n\(error.restErrors?.statusText ?? error.localizedDescription)")
                        }

                        // maybe add in queue an operation to try login multiple times,because it could failed
                        self.retry(with: result, on: queue)
                    }
                }
            } else {
                ApplicationReachability.instance.refreshServerInfo() // XXX maybe limit to some errors?

                showPendingMessage()
                retry(with: result, on: queue)
            }
        }
        ActionManager.instance.sendChange()
    }

    func showPendingMessage() {
        guard self.request.tryCount < 1 else { return }
        let message: String
        if ApplicationReachability.isReachable {
            message = "The server is not available\n your action will be executed later"
        } else {
            message = "Please check your network settings and data cover...\n your action will be executed when online."
        }
        logger.info(message)
        DispatchQueue.main.async {
            SwiftMessages.info(message) { (view, config) -> SwiftMessages.Config in
                view.configureTheme(.info)
                var config = config
                config.presentationContext = .window(windowLevel: .statusBar)
                logger.debug("configure: " + message)
                return config
            }
        }
    }

    override func main () {
        request.state = .executing
        ActionManager.instance.sendChange()
        logger.debug("Action operation: \(request.id) \(request.action.name)")
        let queue = OperationQueue.current as! ActionRequestQueue // swiftlint:disable:this force_cast

        let cancellable = APIManager.instance.action(request, callbackQueue: .background) { (result) in
            self.complete(with: result.mapError({ ActionRequest.Error($0)}), on: queue)
        }
        self.bag.insert(AnyCancellable(cancellable.cancel))
    }

    public override func cancel(with error: ActionRequest.Error) {
        self.request.result = .failure(error)
        super.cancel(with: error)
    }

    func clone() -> ActionRequestOperation {
        return ActionRequestOperation(self.request, self.actionUI, self.context, self.waitUI, self.completionHandler)
    }

}

extension ActionRequest {
    func newOp(_ actionUI: ActionUI, _ context: ActionContext, _ waitUI: ActionExecutor.WaitPresenter, _ actionExecutor: ActionExecutor.CompletionHandler?) -> ActionRequestOperation {
       return ActionRequestOperation(self, actionUI, context, waitUI, actionExecutor)
   }
}
