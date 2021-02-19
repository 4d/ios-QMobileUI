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

        let operation = request.newOp(actionUI, context, waitUI, completionHandler)

        if let actionParameters = request.actionParameters {
            for (_, value) in actionParameters {
                if let subOpInfo = value as? ActionRequestParameterWithRequest {

                    let subOperation = subOpInfo.newOperation(operation)
                    self.addOperation(subOperation)
                    operation.addDependency(subOperation)
                }
            }
        }

        self.add([operation])
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

    func remove(_ operation: ActionRequestOperation) -> Bool {
        /*if operation == self.lastOperation {
         // ignore? (to test ; state , retry, cancel)
         } else {*/
        let dependencies = operation.dependencies
        // first transfert dependencies to next operation
        if let nextOp = operation.nextOperation as? ActionRequestOperation {
            for dependency in dependencies {
                nextOp.addDependency(dependency)
            }
        }
        // cancel current task
        operation.cancel(with: .cancelError)
        for dependency in dependencies {
            operation.removeDependency(dependency)
        }
        /*}*/
        return true // not able to cancel?
    }

    func synced(closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }

    func retry(_ operation: ActionRequestImageOperation) {
        enqueue(operation.clone())
    }
    func enqueue(_ operation: ActionRequestImageOperation) {
        operation.parentOperation.addDependency(operation)
        self.addOperation(operation)
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

    func requestUpdated(_ request: ActionRequest) {
        guard let operation = self.operations.compactMap({$0 as? ActionRequestOperation}).first(where: {$0.request.id == request.id}) else {
            logger.warning("Failed to find corresponding operation for request \(request)")
            return
        }

        let imageOps = operation.dependencies.compactMap({$0 as? ActionRequestImageOperation})

        for (key, value) in request.actionParameters ?? [:] {
            if let imageInfo = value as? ImageUploadOperationInfo { // XXX if we could be more generic using ActionRequestParameterWithRequest, it will be better
                if let imageOp = imageOps.first(where: { $0.info.cacheId == imageInfo.cacheId}) {

                    if imageOp.info.id == imageInfo.id {
                        // already scheduled
                    } else {
                        // same fields but not same operation, cancel the previous one?
                        if !imageOp.isCancelled {
                            imageOp.cancel(with: ActionFormError.upload([key: APIError.request(NSError(domain: "qmobile", code: 100, userInfo: [NSLocalizedDescriptionKey: "Operation cancelled, because a new image must be uploaded"]))]))
                        }
                        // schedule a new one
                        let subOperation = imageInfo.newOperation(operation)
                        self.addOperation(subOperation)
                        operation.addDependency(subOperation)
                    }
                } else {
                    // schedule one if missing
                    let subOperation = imageInfo.newOperation(operation)
                    self.addOperation(subOperation)
                    operation.addDependency(subOperation)
                }
            }
        }
    }
}
