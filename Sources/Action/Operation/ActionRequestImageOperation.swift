//
//  ImageOperation.swift
//  QMobileUI
//
//  Created by emarchand on 17/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileAPI

/// An operation to upload images
class ActionRequestImageOperation: AsynchronousResultOperation<UploadResult, ActionFormError> {

    let info: ImageUploadOperationInfo
    let parentOperation: ActionRequestOperation

    init(_ info: ImageUploadOperationInfo, _ operation: ActionRequestOperation) {
        self.info = info
        self.parentOperation = operation
    }

    override func main() {
        let queue = OperationQueue.current as! ActionRequestQueue // swiftlint:disable:this force_cast
        let info = self.info
        let imageCompletion: APIManager.CompletionUploadResultHandler = { result in
            switch result {
            case .success(let uploadResult):
                logger.debug("Image uploaded \(uploadResult)")
                self.parentOperation.request.setActionParameters(key: info.key, value: uploadResult)
                ActionManager.instance.saveActionRequests()
                info.transfer(to: uploadResult)
                self.finish(with: .success(uploadResult))
            case .failure:
                queue.retry(self)
                ApplicationReachability.instance.refreshServerInfo() // XXX maybe limit to some errors?
                self.finish(with: result.mapError { ActionFormError.upload([info.key: $0]) })
            }
        }
        info.retrieve { result in
            switch result {
            case.success(let result):
                if let image = result.image {
                    APIManager.instance.uploadImage(url: nil, image: image, completion: imageCompletion)
                } else {
                    self.parentOperation.request.removeActionParameters(key: info.key)
                    logger.warning("Do not retrieve image in cache with cache id \(info.cacheId). Maybe already send and cache removed or user remove image cache")
                    self.finish(with: .failure(ActionFormError.upload([info.key: APIError.request(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))])))
                }
            case .failure(let error):
                self.finish(with: .failure(ActionFormError.upload([info.key: APIError.request(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSUnderlyingErrorKey: error]))])))
            }
         }
    }

    func clone() -> ActionRequestImageOperation {
        return ActionRequestImageOperation(self.info, self.parentOperation)
    }
}

protocol ActionRequestParameterWithRequest {

    func newOperation(_ operation: ActionRequestOperation) -> Operation

}

public struct ImageUploadOperationInfo: ActionRequestParameterWithRequest, VeryCodable {

    public var id: String = UUID().uuidString // add an id to make not equal too different image to upload associated to same field (we could when edit change the image) // swiftlint:disable:this identifier_name
    public var cacheId: String

    public var key: String {
        if let range = cacheId.range(of: "_") {
            return String(cacheId[range.upperBound...])
        }
        return cacheId
    }

    public init(cacheId: String) {
        self.cacheId = cacheId
    }

    func newOperation(_ operation: ActionRequestOperation) -> Operation {
        return ActionRequestImageOperation(self, operation)
    }

    public static var codableClassStoreKey: String { return "ImageUploadOperationInfo" }
}

extension ImageUploadOperationInfo: Equatable {
    public static func == (left: ImageUploadOperationInfo, right: ImageUploadOperationInfo) -> Bool {
        return left.cacheId == right.cacheId && left.id == right.id
    }
}

import Kingfisher

public protocol ImageRetrieval {
    var cacheId: String { get }
}

extension ImageRetrieval {

    public func retrieve(callbackQueue: CallbackQueue = .mainCurrentOrAsync, _ completionHandler: @escaping (Result<ImageCacheResult, KingfisherError>) -> Void) {
        ActionManager.instance.cache.retrieve(cacheId: cacheId, callbackQueue: callbackQueue, completionHandler)
    }

    public func awaitRetrieve() -> Result<ImageCacheResult, KingfisherError> {
        let semaphore = DispatchSemaphore(value: 0)
        var theResult: Result<ImageCacheResult, KingfisherError>?
        DispatchQueue.userInitiated.async {
            self.retrieve(callbackQueue: .dispatch(DispatchQueue.userInitiated)) { result in
                theResult = result
                semaphore.signal()
            }
        }
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return theResult!
    }

    public func remove() {
        ActionManager.instance.cache.remove(cacheId: cacheId)
    }

    public func transfer(to: ImageRetrieval) { // swiftlint:disable:this identifier_name
        ActionManager.instance.cache.transfer(from: cacheId, to: to.cacheId)
    }

    public func store(image: UIImage) {
        ActionManager.instance.cache.store(cacheId: cacheId, image: image)
    }
}
extension ImageUploadOperationInfo: ImageRetrieval {}
extension UploadResult: ImageRetrieval {
    public var cacheId: String { id }
}

extension ActionRequest {
    func clean() {
        for parameter in (self.actionParameters ?? [:]).compactMap({ $0.value as? ImageRetrieval }) {
            parameter.remove()
        }
    }
}
