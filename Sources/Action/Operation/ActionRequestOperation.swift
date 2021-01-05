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

class ActionRequestOperation: AsynchronousResultOperation<ActionResult, ActionRequest.Error> {

    weak var nextOperation: Operation?

    var request: ActionRequest

    var actionUI: ActionUI
    var context: ActionContext
    var completionHandler: ActionManager.ActionExecutionCompletionHandler?

    var bag: Cancellable?

    init(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: ActionManager.ActionExecutionCompletionHandler?) {
        self.request = request
        self.actionUI = actionUI
        self.context = context
        self.completionHandler = completionHandler

        super.init()
        self.name = self.request.id + self.request.action.name

        self.onResult = { result in
            self.request.result = result

            switch result {
            case .success(let value):
                logger.error("Action result not managed yet")

                let handle: () -> Void = {
                    onForeground {
                        background {
                            _ =  ActionManager.instance.handle(result: value, for: request.action, from: actionUI, in: context)
                        }
                    }
                }

                if let completionHandler = completionHandler {
                    let future = completionHandler(.success(value)) // close UI
                    // delay handle action result, after form finish with it
                    future.onComplete { _ in
                        handle()
                    }.sink()
                } else {
                    handle()
                }
            case .failure(let error):
                logger.warning(" \(error)")
            }
        }

        self.onStateChanged = { _ in
            //self.request.state = . TODO update  state for UI
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
        case dispatch, operation/*, combine*/
    }

    var retryMode: RetryMode = .operation

    private func retry(with result: Result<ActionResult, ActionRequest.Error>, on queue: ActionRequestQueue) {
        switch self.retryMode {
        case .dispatch:
            self.request.result = result // not finish so set it explictely
            self.main()
        case .operation:
            queue.retry(self)
            self.finish(with: result)
        }
    }

    private func complete(with result: Result<ActionResult, ActionRequest.Error>, on queue: ActionRequestQueue) {
        switch result {
        case .success:
            self.finish(with: result)
        case .failure(let error):
            guard error.mustRetry else {
                self.finish(with: result) // finish with error such as remote server user error
                return
            }
            logger.warning("retry: \(self.request)")

            if !Prephirences.Auth.Login.form, error.isUnauthorized {
                ApplicationAuthenticate.retryGuestLogin { _ in
                    // maybe add in queue an operation to try login multiple times,because it could failed
                    self.retry(with: result, on: queue)
                }
            } else {
                retry(with: result, on: queue)
            }
        }
    }

    override func main () {
        logger.debug("Action operation: \(request.id) \(request.action.name)")
        let queue = OperationQueue.current as! ActionRequestQueue //swiftlint:disable:this force_cast

        bag = APIManager.instance.action(request, callbackQueue: .background) { (result) in
            self.complete(with: result.mapError({ ActionRequest.Error($0)}), on: queue)
        }

      /*
         // subscript on , receive on the operation queue?
         NetworkLayer.requestPublihser(self.request).retry(3).sink { complete in
            if case .failure(let error) = complete {
                self.complete(.failure(error))
            }
        } receiveValue: { actionResult in
            self.complete(.success(actionResult))
        }*/
    }

    func clone() -> ActionRequestOperation {
        return ActionRequestOperation(self.request, self.actionUI, self.context, self.completionHandler)
    }

}

extension ActionRequest {
    func newOp(_ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: ActionManager.ActionExecutionCompletionHandler?) -> ActionRequestOperation {
       return ActionRequestOperation(self, actionUI, context, completionHandler)
   }
}
