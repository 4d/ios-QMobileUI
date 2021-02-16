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

    func retry(_ operation: ImageOperation) {
        enqueue(operation.clone())
    }
    func enqueue(_ operation: ImageOperation) {
        operation.operation.addDependency(operation)
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
}

class ImageOperation: AsynchronousResultOperation<UploadResult, ActionFormError> {

    let info: ImageUploadOperationInfo
    let operation: ActionRequestOperation

    init(_ info: ImageUploadOperationInfo, _ operation: ActionRequestOperation) {
        self.info = info
        self.operation = operation
    }

    override func main() {
        let queue = OperationQueue.current as! ActionRequestQueue // swiftlint:disable:this force_cast
        let cacheId = self.info.cacheId
        let key = info.key
        let imageCompletion: APIManager.CompletionUploadResultHandler = { result in
            switch result {
            case .success(let uploadResult):
                logger.debug("Image uploaded \(uploadResult)")
                self.operation.request.setActionParameters(key: key, value: uploadResult)
                ActionManager.instance.saveActionRequests()
                ActionManager.instance.cache.remove(cacheId: cacheId)
                self.finish(with: .success(uploadResult))
            case .failure:
                queue.retry(self)
                ApplicationReachability.instance.refreshServerInfo() // XXX maybe limit to some errors?
                self.finish(with: result.mapError { ActionFormError.upload([key: $0]) })
            }
        }
        ActionManager.instance.cache.retrieve(cacheId: cacheId) { result in
            switch result {
            case.success(let result):
                if let image = result.image {
                    APIManager.instance.uploadImage(url: nil, image: image, completion: imageCompletion)
                } else {
                    assertionFailure("Do not retrieve image in cache but success? why?")
                    self.finish(with: .failure(ActionFormError.upload([key: APIError.request(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))])))
                }
            case .failure(let error):
                self.finish(with: .failure(ActionFormError.upload([key: APIError.request(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSUnderlyingErrorKey: error]))])))
            }
         }
    }

    func clone() -> ImageOperation {
        return ImageOperation(self.info, self.operation)
    }
}

protocol ActionRequestParameterWithRequest {

    func newOperation(_ operation: ActionRequestOperation) -> Operation

}

struct ImageUploadOperationInfo: ActionRequestParameterWithRequest, Codable {

    var cacheId: String

    var key: String {
        if let range = cacheId.range(of: "_") {
            return String(cacheId[range.upperBound...])
        }
        return cacheId
    }

    func newOperation(_ operation: ActionRequestOperation) -> Operation {
        return ImageOperation(self, operation)
    }
}
