//
//  UIImageView+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

extension UIImageView {

   @objc dynamic public var imageNamed: String? {
        get {
            return self.image?.accessibilityIdentifier
        }
        set {
            guard let name = newValue else {
                self.image = nil
                return
            }
            self.image = UIImage(named: name)
            self.image?.accessibilityIdentifier = name
        }
    }

    @objc dynamic public var systemImageNamed: String? {
         get {
             return self.image?.accessibilityIdentifier
         }
         set {
             guard let name = newValue else {
                 self.image = nil
                 return
             }
             self.image = UIImage(systemName: name)
             self.image?.accessibilityIdentifier = name
         }
     }

    /*@objc dynamic public var localizedText: String? {
        get {
            guard let localized = self.text else {
                return nil
            }
            return localized // Cannot undo it...
        }
        set {
            guard let string = newValue else {
                self.text = nil
                return
            }
            self.text = string.localizedBinding
     }
     }*/

    public var text: String? {
        get {
            guard let image = self.image else {
                return nil
            }
            return "an image \(image)"
        }
        set {
            if let text = newValue {
                logger.warning("A text data field has been binded too this image widget with data \(text)")
                self.image = UIImage.image(from: text, size: self.frame.size)
            } else {
                self.image = nil
            }
        }
    }

}

// MARK: using URL and cache
import Kingfisher
import QMobileAPI
import QMobileDataSync


extension UIImageView {

    public typealias ImageCompletionHandler = ((Result<RetrieveImageResult, KingfisherError>) -> Void)

    // Remove image
    fileprivate func unsetImage() {
        self.kf.indicatorType = .none
        self.image = nil
    }

    @objc dynamic public var restImage: [String: Any]? {
        get {
            return nil
        }
        set {
            // Check if passed value is a compatible restImage dictionary
            guard let imageResource = ApplicationImageCache.imageResource(for: newValue) else {
                unsetImage()
                return
            }
            logger.verbose("Setting \(imageResource) to view \(self)")

            // Setup placeHolder image or other options defined by custom builders
            var options = ApplicationImageCache.options()
            var placeHolderImage: UIImage?
            var indicatorType: IndicatorType = .activity
            if let builder = self as? ImageCacheOptionsBuilder {
                options = builder.option(for: imageResource.downloadURL, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
                indicatorType = builder.indicatorType ?? .activity
            }

            // Check cache, bundle
            ApplicationImageCache.checkCached(imageResource)

            // Do the request
            let completionHandler: ImageCompletionHandler = { result in
                switch result {
                case .success:
                    #if DEBUG
                    assert(ApplicationImageCache.isCached(imageResource)) // if failed maybe preprocessor
                    #endif
                    // self.setNeedsDisplay() // force refresh ??
                case .failure(let error):
                    ApplicationImageCache.log(error: error, for: imageResource.downloadURL)
                    _ = self.kf.setImage(with: imageResource.bundleProvider,
                                         placeholder: placeHolderImage,
                                         options: options,
                                         progressBlock: nil,
                                         completionHandler: nil)
                }
            }
            self.kf.cancelDownloadTask()
            self.kf.indicatorType = indicatorType
            _ = self.kf.setImage(
                with: imageResource,
                placeholder: placeHolderImage,
                options: options,
                progressBlock: nil,
                completionHandler: completionHandler)
        }
    }

    @objc dynamic public var imageURL: String? {
        get {
            return nil
        }
        set {
            guard let newValue = newValue, let url = URL(string: newValue) else {
                unsetImage()
                return
            }
            let imageResource = ImageResource(downloadURL: url)
            logger.verbose("Setting \(imageResource) to view \(self)")

            // Setup placeHolder image or other options defined by custom builders
            var options = ApplicationImageCache.options()
            var placeHolderImage: UIImage?
            var indicatorType: IndicatorType = .activity
            if let builder = self as? ImageCacheOptionsBuilder {
                options = builder.option(for: imageResource.downloadURL, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
                indicatorType = builder.indicatorType ?? .activity
            }

            // Do the request
            let completionHandler: ImageCompletionHandler = { result in
                switch result {
                case .success:
                    // self.setNeedsDisplay() // force refresh ??
                    break
                case .failure(let error):
                    ApplicationImageCache.log(error: error, for: imageResource.downloadURL)
                    _ = self.kf.setImage(with: imageResource,
                                         placeholder: placeHolderImage,
                                         options: options,
                                         progressBlock: nil,
                                         completionHandler: nil)
                }
            }
            self.kf.cancelDownloadTask()
            self.kf.indicatorType = indicatorType
            _ = self.kf.setImage(
                with: imageResource,
                placeholder: placeHolderImage,
                options: options,
                progressBlock: nil,
                completionHandler: completionHandler)
        }
    }

    @objc dynamic public var imageData: Data? {
        get {
            guard let image = self.image else {
                return nil
            }
            return image.pngData()
        }
        set {
            if let data = newValue {
                self.image = UIImage(data: data)
            } else {
                self.image = nil
            }
        }
    }

}
