//
//  UIImageView+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

/*
extension UIImageView {

    public var imageNamed: String? {
        get {
            return (self.image as? UIImageNamed)?.name
        }
        set {
            guard let name = newValue else {
                self.image = nil
            }
            self.image = UIImage(named: name)
        }
    }

}

// UIImage extension to keep a reference on the name
fileprivate class UIImageNamed: UIImage {
    fileprivate let name: String

    required init(imageLiteralResourceName name: String) {
        self.name = name
        super.init(imageLiteralResourceName: name)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}*/

// MARK: using URL and cache
import Kingfisher
import QMobileAPI

extension UIImageView {

    public var webURL: URL? {
        get {
            return self.kf.webURL
        }
        set {
            if newValue != nil {
                self.kf.indicatorType = .activity
            }
            // could add a processor
            // https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#built-in-processors-of-kingfisher
            // let processor = BlurImageProcessor(blurRadius: 4) >> RoundCornerImageProcessor(cornerRadius: 20)
            // options: [.processor(processor)] // , .cacheOriginalImage

            self.kf.setImage(with: newValue, placeholder: nil, options: nil)
        }
    }

}

import QMobileAPI
import QMobileDataSync

/// Protocol allowing to customize rest image download using Kingfisher option api.
public protocol KingfisherOptionsInfoBuilder {

    /// Return the new options to display or download the images.
    func option(for url: URL, currentOptions options: KingfisherOptionsInfo) -> KingfisherOptionsInfo

    var placeHolderImage: UIImage? { get }

    var indicatorType: IndicatorType? { get }

}

extension UIImageView {

    public typealias CompletionHandler = ((_ image: Image?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: URL?) -> Void)

    @objc dynamic public var restImage: [String: Any]? {
        get {
            if let webURL =  self.webURL {
                var uri = webURL.absoluteString
                // remove the base url
                uri = uri.replacingOccurrences(of: DataSync.instance.rest.rest.baseURL.absoluteString, with: "")
                let deffered = Deferred(uri: uri, image: true)
                return deffered.dictionary
            }
            return nil
        }
        set {
            // Check if passed value is a compatible restImage dictionary
            guard let imageResource = ApplicationImageCache.imageResource(for: newValue) else {
                // Remove image
                self.kf.indicatorType = .none
                self.image = nil
                return
            }

            // Setup placeHolder image or other options defined by custom builders
            var options: KingfisherOptionsInfo = []
            var placeHolderImage: UIImage?
            var indicatorType: IndicatorType = .activity
            if let builder = self as? KingfisherOptionsInfoBuilder {
                options = builder.option(for: imageResource.downloadURL, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
                indicatorType = builder.indicatorType ?? .activity
            }
            let imageCache = options.targetCache

            /// Get from bundle
            var hasSetImage = false
            if !imageCache.imageCachedType(forKey: imageResource.cacheKey).cached {
                // Fill cache with bundle -> XXX  result double copy on disk -> could do better by having bundle as disk cache backend
                if let image = ApplicationImageCache.imageInBundle(for: imageResource) {

                    imageCache.store(image, forKey: imageResource.cacheKey)
                    self.image = image
                    options += [.keepCurrentImageWhileLoading]
                    hasSetImage = true
                }
            }
            if !hasSetImage {
                self.kf.indicatorType = indicatorType
                self.image = placeHolderImage
            }

            // Setup some request modification
            let modifier = AnyModifier { request in
                return APIManager.instance.configure(request: request)
            }
            options += [.requestModifier(modifier)]

            // Do the request
            let completionHandler: CompletionHandler = { image, error, cacheType, imageURL in
                self.setNeedsDisplay()
            }
            self.kf.cancelDownloadTask()
            _ = self.kf.setImage(with: imageResource,
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
            return UIImagePNGRepresentation(image)
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
