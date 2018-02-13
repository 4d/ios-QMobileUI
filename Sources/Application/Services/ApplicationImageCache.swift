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

class ApplicationImageCache: NSObject {
    var listeners: [NSObjectProtocol] = []
}

extension ApplicationImageCache: ApplicationService {

    static var instance: ApplicationService = ApplicationImageCache()

    static var pref: MutablePreferencesType {
        return MutableProxyPreferences(preferences: preferences, key: "imageCache.", separator: "")
    }

    static var atLaunch: Bool {
        return pref["atLaunch"] as? Bool ?? false
    }
    static var atLaunchDone: Bool {
        get {
            return pref["atLaunchDone"] as? Bool ?? false
        }
        set {
            pref.set(newValue, forKey: "atLaunchDone")
        }
    }
    static var subdirectory: String {
        return pref["subdirectory"] as? String ?? "Pictures"
    }
    static var `extension`: String {
        return pref["extension"] as? String ?? "png"
    }
    public static func fill(imageCache: ImageCache = .default, from bundle: Bundle = .main) {
        let subdirectory = self.subdirectory
        let ext = self.extension
        if let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) {
            for url in urls {
                let cacheKey = url.deletingPathExtension().lastPathComponent
                if !imageCache.imageCachedType(forKey: cacheKey).cached {
                    if let image = Image(url: url) {
                        imageCache.store(image, forKey: cacheKey)
                    }
                }
            }
        }
    }

    public static func clear(imageCache: ImageCache = .default) {
        imageCache.clearDiskCache()
        imageCache.clearMemoryCache()
    }

    private static func fillAtLaunch() {
        if atLaunch {
            if !atLaunchDone {
                fill()
                atLaunchDone = true
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        ApplicationImageCache.fillAtLaunch()

       /* listeners += [NotificationCenter.default.addObserver(forName: .dataSyncSuccess) { (_: Notification) in
             // XXX  reset cache image ?
            }]*/
    }

    func applicationWillTerminate(_ application: UIApplication) {
        /*for listener in listeners {
            NotificationCenter.default.removeObserver(listener)
        }*/
    }
}
