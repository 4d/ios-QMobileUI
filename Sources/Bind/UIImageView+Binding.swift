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
}

extension UIImageView {

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
            if let dico = newValue, let uri = ImportableParser.parseImage(dico) {
                self.kf.indicatorType = .activity
                let fullUri = DataSync.instance.rest.rest.baseURL.absoluteString + uri
                if let url = URL(string: fullUri) {

                    let modifier = AnyModifier { request in
                        return APIManager.instance.configure(request: request)
                    }
                    var options: KingfisherOptionsInfo = [.requestModifier(modifier)]
                    var placeHolderImage: UIImage?
                    if let builder = self as? KingfisherOptionsInfoBuilder {
                        options = builder.option(for: url, currentOptions: options)
                        placeHolderImage = builder.placeHolderImage
                    }
                    self.kf.setImage(with: url,
                                     placeholder: placeHolderImage,
                                     options: options)
                }

            } else {
                self.kf.indicatorType = .none
            }
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
