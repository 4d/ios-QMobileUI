//
//  ApplicationLaunchOptions.swift
//  QMobileUI
//
//  Created by Eric Marchand on 27/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

public class ApplicationLaunchOptions {

    public static let instance = ApplicationLaunchOptions()

    public var apns: [AnyHashable: Any]?
    public var sourceApplication: String?
    public var url: URL?
    public var shortcut: [String: NSSecureCoding]?
    public var userActivity: NSUserActivity?

}

extension ApplicationLaunchOptions: ApplicationService {

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        url = launchOptions?[.url] as? URL
        sourceApplication = launchOptions?[.sourceApplication] as? String
        apns = launchOptions?[.remoteNotification] as? [AnyHashable: Any]
        shortcut = (launchOptions?[.shortcutItem] as? UIApplicationShortcutItem)?.userInfo
        userActivity = launchOptions?[.userActivityType] as? NSUserActivity
    }

}
