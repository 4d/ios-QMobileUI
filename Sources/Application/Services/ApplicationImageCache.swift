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

    static var instance: ApplicationService = ApplicationImageCache()

    private static var instanceCached: ApplicationImageCache {
        //swiftlint:disable:next force_cast
        return instance as! ApplicationImageCache
    }

    private lazy var imageCache: ImageCache = { ImageCache(name: "imageCache") { (_, _) -> String in
        let dstPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent("imageCache")
        }}()

    private lazy var pref: MutablePreferencesType = {
        return MutableProxyPreferences(preferences: preferences, key: "imageCache.", separator: "")
    }()

    private lazy var subdirectory: String = {
        return pref["subdirectory"] as? String ?? "Pictures"
    }()
    private lazy var `extension`: String = {
        return pref["extension"] as? String ?? "png"
    }()

    private lazy var clearOnReload: Bool = {
        return pref["clear.onReload"] as? Bool ?? false
    }()

    private lazy var clearAtLaunch: Bool = {
        return pref["clear.atLaunch"] as? Bool ?? false
    }()

    private lazy var forceRefresh: Bool = {
        return pref["forceRefresh"] as? Bool ?? false
    }()

    private lazy var onlyFromCache: Bool = {
        return pref["noNetwork"] as? Bool ?? false
    }()

    private lazy var cacheMemoryOnly: Bool = {
        return pref["memoryOnly"] as? Bool ?? false
    }()

    private lazy var atLaunch: Bool = {
        return pref["fill.atLaunch"] as? Bool ?? false
    }()

    private var atLaunchDone: Bool {
        get {
            return pref["atLaunchDone"] as? Bool ?? false
        }
        set {
            pref.set(newValue, forKey: "atLaunchDone")
        }
    }

}

extension ApplicationImageCache {
    // MARK: function
    private func fill(from bundle: Bundle = .main) {
        guard let urls = bundle.urls(forResourcesWithExtension: self.extension, subdirectory: subdirectory) else {
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

    public static func clear() {
        instanceCached.imageCache.clearDiskCache()
        instanceCached.imageCache.clearMemoryCache()
    }

    public static func imageResource(for restDictionary: [String: Any]?) -> RestImageResource? {
        return RestImageResource(restDictionary: restDictionary)
    }

    private static func imageInBundle(for resource: RestImageResource) -> UIImage? {
        if let url = Bundle.main.url(forResource: resource.cacheKey,
                                     withExtension: resource.extension ?? instanceCached.extension,
                                     subdirectory: instanceCached.subdirectory) {
            return UIImage(url: url)
        }
        return nil
    }

    static func options() -> KingfisherOptionsInfo {
        let modifier = AnyModifier { request in // Setup some request modification
            return APIManager.instance.configure(request: request)
        }
        var options: KingfisherOptionsInfo = [
            .targetCache(instanceCached.imageCache),
            .requestModifier(modifier)
        ]
        if instanceCached.forceRefresh {
            options.append(.forceRefresh)
        }
        if instanceCached.onlyFromCache {
            options.append(.onlyFromCache)
        }
        if instanceCached.cacheMemoryOnly {
            options.append(.cacheMemoryOnly)
        }
        return options
    }

    public static func store(image: UIImage, for restDictionary: [String: Any]?) {
        if let resource = imageResource(for: restDictionary) {
            store(image: image, for: resource)
        }
    }

    public static func store(image: UIImage, for resource: RestImageResource) {
        instanceCached.imageCache.store(image, forKey: resource.cacheKey, toDisk: !instanceCached.cacheMemoryOnly)
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
        if !isCached(imageResource),
            let image = imageInBundle(for: imageResource) {
            store(image: image, for: imageResource)
        }
    }

    private static func isCached(_ imageResource: RestImageResource) -> Bool {
        return instanceCached.imageCache.imageCachedType(forKey: imageResource.cacheKey).cached
    }

}

extension ApplicationImageCache: ApplicationService {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if atLaunch {
            if !atLaunchDone {
                fill()
                atLaunchDone = true
            }
        } else if clearAtLaunch {
            ApplicationImageCache.clear()
        }

        let center = NotificationCenter.default
        let listener = center.addObserver(forName: .dataSyncSuccess, object: nil, queue: .main) { (_) in
            if self.clearOnReload {
                ApplicationImageCache.clear()
            }
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

    var cacheKey: String
    var downloadURL: URL

    init?(restDictionary: [String: Any]?) {
        guard let restDictionary = restDictionary,
            let uri = ImportableParser.parseImage(restDictionary) else {
                return nil
        }

        let restTarget = DataSync.instance.apiManager.base
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

// MARK: Application
extension QApplication {

    /// Clear image cache.
    public func clearImageCache() {
        ApplicationImageCache.clear()
    }

}
