//
//  ApplicationService.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/12/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Protocol for an application service. @see UIApplicationDelegate.
public protocol ApplicationService {

    // MARK: application flow
    var services: [ApplicationService] { get }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)

    func applicationDidEnterBackground(_ application: UIApplication)

    func applicationWillEnterForeground(_ application: UIApplication)

    func applicationDidBecomeActive(_ application: UIApplication)

    func applicationWillResignActive(_ application: UIApplication)

    func applicationWillTerminate(_ application: UIApplication)

    func applicationDidReceiveMemoryWarning(_ application: UIApplication)

    // MARK: application receive url or token

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any])

    // MARK: User activity

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool

    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error)

    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity)

}

extension ApplicationService {

    public var services: [ApplicationService] { return [] }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        services.forEach { service in
            service.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        services.forEach { service in
            service.applicationDidEnterBackground(application)
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        services.forEach { service in
            service.applicationWillEnterForeground(application)
        }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        services.forEach { service in
            service.applicationDidBecomeActive(application)
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        services.forEach { service in
            service.applicationWillResignActive(application)
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        services.forEach { service in
            service.applicationWillTerminate(application)
        }
    }

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        services.forEach { service in
            service.applicationDidReceiveMemoryWarning(application)
        }
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        services.forEach { service in
            service.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        services.forEach { service in
            service.application(application, open: url, options: options)
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        var result = false
        services.forEach { service in
            result = service.application(application, continue: userActivity, restorationHandler: restorationHandler) || result
        }
        return result

    }

    public func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        var result = false
        services.forEach { service in
            result = service.application(application, willContinueUserActivityWithType: userActivityType) || result
        }
        return result

    }

    public func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        services.forEach { service in
            service.application(application, didFailToContinueUserActivityWithType: userActivityType, error: error)
        }
    }

    public func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        services.forEach { service in
            service.application(application, didUpdate: userActivity)
        }
    }

}
