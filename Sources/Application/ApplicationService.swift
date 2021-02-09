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
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any])

    // MARK: User activity

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool

    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error)

    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity)

}

// Remap notifications to all services
fileprivate extension Notification {
    var application: UIApplication {
        // swiftlint:disable:next force_cast
        return self.object as! UIApplication
    }
}

extension ApplicationService {

    public var services: [ApplicationService] { return [] }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        services.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        services.applicationDidEnterBackground(application)
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        services.applicationWillEnterForeground(application)
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        services.applicationDidBecomeActive(application)
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        services.applicationWillResignActive(application)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        services.applicationWillTerminate(application)
    }

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        services.applicationDidReceiveMemoryWarning(application)
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        services.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        services.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        services.application(application, open: url, options: options)
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return services.application(application, continue: userActivity, restorationHandler: restorationHandler)

    }

    public func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return services.application(application, willContinueUserActivityWithType: userActivityType)

    }

    public func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        services.application(application, didFailToContinueUserActivityWithType: userActivityType, error: error)
    }

    public func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        services.application(application, didUpdate: userActivity)
    }

}

extension Sequence where Element == ApplicationService {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        self.forEach { service in
            service.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        self.forEach { service in
            service.applicationDidEnterBackground(application)
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        self.forEach { service in
            service.applicationWillEnterForeground(application)
        }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        self.forEach { service in
            service.applicationDidBecomeActive(application)
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        self.forEach { service in
            service.applicationWillResignActive(application)
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        self.forEach { service in
            service.applicationWillTerminate(application)
        }
    }

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        self.forEach { service in
            service.applicationDidReceiveMemoryWarning(application)
        }
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.forEach { service in
            service.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.forEach { service in
            service.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        self.forEach { service in
            service.application(application, open: url, options: options)
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        var result = false
        self.forEach { service in
            result = service.application(application, continue: userActivity, restorationHandler: restorationHandler) || result
        }
        return result
    }

    public func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        var result = false
        self.forEach { service in
            result = service.application(application, willContinueUserActivityWithType: userActivityType) || result
        }
        return result

    }

    public func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        self.forEach { service in
            service.application(application, didFailToContinueUserActivityWithType: userActivityType, error: error)
        }
    }

    public func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        self.forEach { service in
            service.application(application, didUpdate: userActivity)
        }
    }

    public func application(didFinishLaunching notification: Notification) {
        self.forEach { service in
            service.application(notification.application, didFinishLaunchingWithOptions: notification.userInfo as? [UIApplication.LaunchOptionsKey: Any])
        }
    }

    public func application(didEnterBackground notification: Notification) {
        self.forEach { service in
            service.applicationDidEnterBackground(notification.application)
        }
    }

    public func application(willEnterForeground notification: Notification) {
        self.forEach { service in
            service.applicationWillEnterForeground(notification.application)
        }
    }

    public func application(didBecomeActive notification: Notification) {
        self.forEach { service in
            service.applicationDidBecomeActive(notification.application)
        }
    }

    public func application(willResignActive notification: Notification) {
        self.forEach { service in
            service.applicationWillResignActive(notification.application)
        }
    }

    public func application(willTerminate notification: Notification) {
        self.forEach { service in
            service.applicationWillTerminate(notification.application)
        }
    }

    public func application(didReceiveMemoryWarning notification: Notification) {
        self.forEach { service in
            service.applicationDidReceiveMemoryWarning(notification.application)
        }
    }

    public func application(openUrlWithOptions notification: Notification) {
        guard let url = notification.userInfo?[ApplicationServiceUserInfoKey.openUrl] as? URL,
            let options = notification.userInfo?[ApplicationServiceUserInfoKey.openUrlOptions] as? [UIApplication.OpenURLOptionsKey: Any] else {
                return
        }
        application(notification.application, open: url, options: options)
    }

    public func application(didRegisterForRemoteWithDeviceToken notification: Notification) {
        if let data = notification.userInfo?[ApplicationServiceUserInfoKey.deviceToken] as? Data {
            self.forEach { service in
                service.application(notification.application, didRegisterForRemoteNotificationsWithDeviceToken: data)
            }
        }
    }
    public func application(didFailToRegisterForRemoteNotifications notification: Notification) {
        if let error = notification.userInfo?[ApplicationServiceUserInfoKey.error] as? Error {
            self.forEach { service in
                service.application(notification.application, didFailToRegisterForRemoteNotificationsWithError: error)
            }
        }
    }

    public func application(continueUserActivity notification: Notification) {
        if let userActivity = notification.userInfo?[ApplicationServiceUserInfoKey.userActivity] as? NSUserActivity,
            let restorationHandler = notification.userInfo?[ApplicationServiceUserInfoKey.restorationHandler] as? (([Any]?) -> Void) {
            self.forEach { service in
                _ = service.application(notification.application, continue: userActivity, restorationHandler: restorationHandler)
            }
        }
    }

    public func application(willContinueUserActivity notification: Notification) {
        if let userActivityType = notification.userInfo?[ApplicationServiceUserInfoKey.userActivity] as? String {
            self.forEach { service in
                _ = service.application(notification.application, willContinueUserActivityWithType: userActivityType)
            }
        }
    }

    public func application(didFailToContinueUserActivity notification: Notification) {
        if let userActivityType = notification.userInfo?[ApplicationServiceUserInfoKey.userActivity] as? String,
            let error = notification.userInfo?[ApplicationServiceUserInfoKey.error] as? Error {
            self.forEach { service in
                service.application(notification.application, didFailToContinueUserActivityWithType: userActivityType, error: error)
            }
        }
    }

    public func application(didUpdateUserActivity notification: Notification) {
        if let userActivity = notification.userInfo?[ApplicationServiceUserInfoKey.userActivity] as? NSUserActivity {
            self.forEach { service in
                service.application(notification.application, didUpdate: userActivity)
            }
        }
    }
}
