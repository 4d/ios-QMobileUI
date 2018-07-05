//
//  ApplicationImageCache.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

import UIKit
import Kingfisher
import Prephirences
import QMobileDataSync
import QMobileAPI

class ApplicationImageCache: NSObject {
    var listeners: [NSObjectProtocol] = []
}

extension ApplicationImageCache {

    static var instance: ApplicationService = ApplicationImageCache()

    private static let imageCache: ImageCache = ImageCache(name: "imageCache") { (_, _) -> String in
        let dstPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent("imageCache")
    }

    private static var pref: MutablePreferencesType {
        return MutableProxyPreferences(preferences: preferences, key: "imageCache.", separator: "")
    }

    private static var atLaunch: Bool {
        return pref["atLaunch"] as? Bool ?? false
    }
    private static var atLaunchDone: Bool {
        get {
            return pref["atLaunchDone"] as? Bool ?? false
        }
        set {
            pref.set(newValue, forKey: "atLaunchDone")
        }
    }
    private static var subdirectory: String {
        return pref["subdirectory"] as? String ?? "Pictures"
    }
    private static var `extension`: String {
        return pref["extension"] as? String ?? "png"
    }

    // MARK: function
    private static func fill(from bundle: Bundle = .main) {
        guard let urls = bundle.urls(forResourcesWithExtension: self.extension, subdirectory: self.subdirectory) else {
            return

        }
        for url in urls {
            let cacheKey = url.deletingPathExtension().lastPathComponent
            if !imageCache.imageCachedType(forKey: cacheKey).cached {
                if let image = Image(url: url) {
                    imageCache.store(image, forKey: cacheKey)
                }
            }
        }
    }

    private static func clear() {
        imageCache.clearDiskCache()
        imageCache.clearMemoryCache()
    }

    static func imageResource(for restDictionary: [String: Any]?) -> RestImageResource? {
        return RestImageResource(restDictionary: restDictionary)
    }

    private static func imageInBundle(for resource: RestImageResource) -> UIImage? {
        if let url = Bundle.main.url(forResource: resource.cacheKey,
                                     withExtension: resource.extension ?? self.extension,
                                     subdirectory: self.subdirectory) {
            return UIImage(url: url)
        }
        return nil
    }

    static func options() -> KingfisherOptionsInfo {
        let modifier = AnyModifier { request in // Setup some request modification
            return APIManager.instance.configure(request: request)
        }
        return [
            .targetCache(ApplicationImageCache.imageCache),
            .requestModifier(modifier)
        ]
    }

    private static func store(image: UIImage, for resource: RestImageResource) {
        imageCache.store(image, forKey: resource.cacheKey)
    }

    static func log(error: NSError, for imageURL: URL?) {
        if let kfError = KingfisherError.from(error) {
            switch kfError {
            case .downloadCancelledBeforeStarting:
                logger.warning("Task for \(String(describing: imageURL)) cancelled")
            default:
                logger.warning("Failed to download image \(String(describing: imageURL)): \(kfError)")
            }
        } else {
            logger.warning("Failed to download image \(String(describing: imageURL)): \(error)")
        }
    }

    static func checkCached(_ imageResource: RestImageResource) {
        if !ApplicationImageCache.isCached(imageResource),
            let image = ApplicationImageCache.imageInBundle(for: imageResource) {
            ApplicationImageCache.store(image: image, for: imageResource)
        }
    }

    private static func isCached(_ imageResource: RestImageResource) -> Bool {
        return imageCache.imageCachedType(forKey: imageResource.cacheKey).cached
    }

    private static func fillAtLaunch() {
            if atLaunch {
                if !atLaunchDone {
                fill()
                atLaunchDone = true
            }
        }
    }
}

extension ApplicationImageCache: ApplicationService {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        ApplicationImageCache.fillAtLaunch()

        let center = NotificationCenter.default
        let listener = center.addObserver(forName: .dataSyncSuccess, object: nil, queue: .main) { (_) in
            ApplicationImageCache.clear()
        }
        listeners += [listener]
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let center = NotificationCenter.default
        for listener in listeners {
            center.removeObserver(listener)
        }
    }
}

// MARK: resource
struct RestImageResource: Resource {

    var restDictionary: [String: Any]?
    var cacheKey: String
    var downloadURL: URL

    init?(restDictionary: [String: Any]?) {
        guard let restDictionary = restDictionary,
            let uri = ImportableParser.parseImage(restDictionary) else {
                return nil
        }

        let restTarget = DataSync.instance.rest.base
        let urlString = restTarget.baseURL.absoluteString
            + (uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri)
        guard let components = URLComponents(string: urlString), let url = components.url else {
            logger.warning("Cannot encode URI \(uri) to download image from 4D server")
            return nil
        }
        let version = components.queryItems?.filter { $0.name == "$version"}.first?.value ?? ""
        let cacheKey = components.path
            .replacingOccurrences(of: "/"+restTarget.path+"/", with: "")
            .replacingOccurrences(of: "/", with: "_")+"_"+version
        self.downloadURL = url
        self.cacheKey = cacheKey
    }

    var `extension`: String? {
        return nil // could return according to restDictionary maybe nil if "best"
    }

}

// MARK: error
extension KingfisherError: Error {

    static func from(_ nsError: NSError) -> KingfisherError? {
        guard nsError.domain == KingfisherErrorDomain else {
            return nil
        }
        return KingfisherError(rawValue: nsError.code)
    }

}

/// Protocol allowing to customize rest image download using Kingfisher option api.
protocol ImageCacheOptionsBuilder {

    /// Return the new options to display or download the images.
    func option(for url: URL, currentOptions options: KingfisherOptionsInfo) -> KingfisherOptionsInfo

    var placeHolderImage: UIImage? { get }

    var indicatorType: IndicatorType? { get }

}
