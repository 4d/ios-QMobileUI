//
//  ActionRequestQueue.swift
//  QMobileUI
//
//  Created by phimage on 05/11/2020.
//

import Foundation

import QMobileAPI

class ActionRequestQueue: OperationQueue {

    weak var lastOperation: ActionRequestOperation?

    override init() {
        super.init()
        self.qualityOfService = .userInitiated
        self.maxConcurrentOperationCount = 1
        self.name = "ActionRequestQueue"
    }

    func addRequest(_ request: ActionRequest, _ actionUI: ActionUI, _ context: ActionContext, _ waitUI: ActionExecutor.WaitPresenter, _ completionHandler: ActionExecutor.CompletionHandler?) {
        self.add([request.newOp(actionUI, context, waitUI, completionHandler)])
    }

    /*func addRequests(_ requests: [ActionRequest]) {
        self.add(requests.map { $0.newOp() })
    }*/

    fileprivate func add(_ operations: [ActionRequestOperation]) {
        // chain operations
        for operation in operations {
            synced {
                var mustSendSuspended = isSuspended
                if let previousOperation = lastOperation {
                    operation.addDependency(previousOperation)

                    mustSendSuspended = mustSendSuspended || !operation.isFinished

                    #if DEBUG
                    logger.verbose("\(previousOperation.request.action.name) -> \(operation.request.action.name) ")
                    #endif
                }
                if mustSendSuspended { // dirty way to send error to action next in queue, to stop UI
                    operation.completionHandler?(.success(ActionResult(success: true, json: JSON(["statusText": "Request enqueued"]))))
                    // self.completionHandler?(.failure(ActionRequest.Error(APIError.error(from: NSError()))))
                }
                lastOperation = operation
            }
        }
        addOperations(operations, waitUntilFinished: false)
    }

    func synced(closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }

    func retry(_ operation: ActionRequestOperation) {
        // we enqueue a new operation between passed operation and its next one
        enqueue(operation.clone(), after: operation)
    }

    func enqueue(_ operation: ActionRequestOperation, after previousOperation: ActionRequestOperation) {
        let nextOperation = previousOperation.nextOperation // /!\ get next before changing it by retry op

        // schedule the retry operation
        operation.addDependency(previousOperation)
        self.addOperation(operation)

        // replace in next operation
        if let nextOperation = nextOperation {
            nextOperation.addDependency(operation)
            nextOperation.removeDependency(previousOperation)
        } else {
            synced {
                if lastOperation == previousOperation {
                    lastOperation = operation
                } else {
                    logger.warning("No next operation defined in action operation queue")
                }
            }
        }

    }
}
