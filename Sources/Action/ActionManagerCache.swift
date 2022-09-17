//
//  ActionManagerCache.swift
//  QMobileUI
//
//  Created by emarchand on 16/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import FileKit

class ActionManagerCache {

    lazy var imageCache: ImageCache = {
        return try! ImageCache(name: "uploadCache", cacheDirectoryURL: nil) { (_, _) -> URL in // swiftlint:disable:this force_try
            let path: Path = (Path.userCaches + "uploadCache")
            return path.url
        }}()

    func store(cacheId: String, image: UIImage) {
        imageCache.store(image, forKey: cacheId)
    }

    func retrieve(cacheId: String, callbackQueue: CallbackQueue = .mainCurrentOrAsync, _ completionHandler: @escaping (Result<ImageCacheResult, KingfisherError>) -> Void) {
        imageCache.retrieveImage(forKey: cacheId, callbackQueue: callbackQueue, completionHandler: completionHandler)
    }

    func remove(cacheId: String) {
        imageCache.removeImage(forKey: cacheId)
    }

    func transfer(from: String, to: String) { // swiftlint:disable:this identifier_name
        imageCache.retrieveImage(forKey: from) { result in
            switch result {
            case .success(let imageResult):
                if let image = imageResult.image {
                    self.imageCache.store(image, forKey: to)
                }
            case .failure:
                logger.warning("No image to transfert in cache")
            }
            self.imageCache.removeImage(forKey: from)
        }
    }
}
