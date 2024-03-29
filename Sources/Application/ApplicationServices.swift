//
//  ApplicationServices.swift
//  QMobileUI
//
//  Created by Eric Marchand on 01/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Application service manager
public class ApplicationServices {

    var center: NotificationCenter = NotificationCenter.default

    public private(set) var services: [ApplicationService] = []

    public class var instance: ApplicationServices { return applicationServices }

    public func register(_ service: ApplicationService) {
        services.append(service)
    }

    // prevent external init ie. singleton
    fileprivate init() {}

}

// launch setup immediately
private let applicationServices = ApplicationServices().setup()
fileprivate extension ApplicationServices {

    func setup() -> Self {
        addObservers()
        return self
    }

    func addObservers() {
        center.addObserver(self, selector: #selector(application(didFinishLaunching:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
        center.addObserver(self, selector: #selector(application(didEnterBackground:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(application(willEnterForeground:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(application(didBecomeActive:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(application(willResignActive:)), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(application(didReceiveMemoryWarning:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        center.addObserver(self, selector: #selector(application(willTerminate:)), name: UIApplication.willTerminateNotification, object: nil)
        /* // status bar event
         .UIApplicationWillChangeStatusBarOrientation
         .UIApplicationDidChangeStatusBarOrientation
         .UIApplicationWillChangeStatusBarFrame
         .UIApplicationDidChangeStatusBarFrame
         .UIApplicationBackgroundRefreshStatusDidChange
         */

        // receive info
        center.addObserver(self, selector: #selector(application(didRegisterForRemoteWithDeviceToken:)), name: UIApplication.didRegisterForRemoteWithDeviceTokenNotification, object: nil)
        center.addObserver(self, selector: #selector(application(didFailToRegisterForRemoteNotifications:)), name: UIApplication.didFailToRegisterForRemoteNotifications, object: nil)
        center.addObserver(self, selector: #selector(application(openUrlWithOptions:)), name: UIApplication.openUrlWithOptionsNotification, object: nil)
        // activity
        center.addObserver(self, selector: #selector(application(didUpdateUserActivity:)), name: UIApplication.didUpdateUserActivityNotification, object: nil)
        center.addObserver(self, selector: #selector(application(didFailToContinueUserActivity:)), name: UIApplication.didFailToContinueUserActivityNotification, object: nil)
        center.addObserver(self, selector: #selector(application(willContinueUserActivity:)), name: UIApplication.willContinueUserActivityNotification, object: nil)
        center.addObserver(self, selector: #selector(application(continueUserActivity:)), name: UIApplication.continueUserActivityNotification, object: nil)
    }

    func removeObjservers() {
        center.removeObserver(self)
    }

}

extension ApplicationServices {

    /// Could call this function to easily register application services
    public func then(_ block: (_ services: ApplicationServices) -> Void) -> Self {
        block(self)
        return self
    }

}

// Special notifications
public struct ApplicationServiceUserInfoKey {
    public static let openUrl = "__openUrl"
    public static let openUrlOptions = "__openUrlOptions"
    public static let deviceToken = "__deviceToken"
    public static let userActivity = "__userActivity"
    public static let error = "__error"
    public static let restorationHandler = "__restorationHandler"
}

extension UIApplication {

    public static let openUrlWithOptionsNotification: Notification.Name = .init("UIApplicationOpenUrlWithOptions")
    // swiftlint:disable:next identifier_name
    public static let didRegisterForRemoteWithDeviceTokenNotification: NSNotification.Name = .init("UIApplicationDidRegisterForRemoteWithDeviceToken")
    public static let didFailToRegisterForRemoteNotifications: NSNotification.Name = .init("UIApplicationDidFailToRegisterForRemoteNotifications")

    public static let didUpdateUserActivityNotification: NSNotification.Name = .init("UIApplicationDidUpdateUserActivity")
    // swiftlint:disable:next identifier_name
    public static let didFailToContinueUserActivityNotification: NSNotification.Name = .init("UIApplicationDidFailToContinueUserActivity")
    public static let willContinueUserActivityNotification: NSNotification.Name = .init("UIApplicationWillContinueUserActivity")
    public static let continueUserActivityNotification: NSNotification.Name = .init("UIApplicationContinueUserActivity")

}
// create missing notifications
public extension UIApplicationDelegate {

    static func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ApplicationServices.instance.center.post(name: UIApplication.didRegisterForRemoteWithDeviceTokenNotification, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.deviceToken: deviceToken])
    }

    static func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ApplicationServices.instance.center.post(name: UIApplication.didFailToRegisterForRemoteNotifications, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.error: error])
    }

    static func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationServices.instance.center.post(name: UIApplication.openUrlWithOptionsNotification, object: app,
                                                 userInfo: [ApplicationServiceUserInfoKey.openUrl: url, ApplicationServiceUserInfoKey.openUrlOptions: options])
        return true
    }

    /*func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return type(of: self).application(app, open: url, options: options)
     }*/

    static func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        ApplicationServices.instance.center.post(name: UIApplication.continueUserActivityNotification, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.userActivity: userActivity, ApplicationServiceUserInfoKey.restorationHandler: restorationHandler])
        return true // no good answer here, or we must wait respond from all listeners
    }

    static func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        ApplicationServices.instance.center.post(name: UIApplication.willContinueUserActivityNotification, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.userActivity: userActivityType])
        return true // no good answer here, or we must wait respond from all listeners
    }

    static func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        ApplicationServices.instance.center.post(name: UIApplication.didFailToContinueUserActivityNotification, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.userActivity: userActivityType, ApplicationServiceUserInfoKey.error: error])
    }

    static func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        ApplicationServices.instance.center.post(name: UIApplication.didUpdateUserActivityNotification, object: application,
                                                 userInfo: [ApplicationServiceUserInfoKey.userActivity: userActivity])
    }

}

extension ApplicationServices {
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        services.application(app, open: url, options: options)
    }
}

private extension ApplicationServices {

    @objc func application(didFinishLaunching notification: Notification) {
        services.application(didFinishLaunching: notification)
    }

    @objc func application(didEnterBackground notification: Notification) {
        services.application(didEnterBackground: notification)
    }

    @objc func application(willEnterForeground notification: Notification) {
        services.application(willEnterForeground: notification)
    }

    @objc func application(didBecomeActive notification: Notification) {
        services.application(didBecomeActive: notification)
    }

    @objc func application(willResignActive notification: Notification) {
        services.application(willResignActive: notification)
    }

    @objc func application(willTerminate notification: Notification) {
        services.application(willTerminate: notification)
    }

    @objc func application(didReceiveMemoryWarning notification: Notification) {
        services.application(didReceiveMemoryWarning: notification)
    }

    @objc func application(openUrlWithOptions notification: Notification) {
        services.application(openUrlWithOptions: notification)
    }

    @objc func application(didRegisterForRemoteWithDeviceToken notification: Notification) {
        services.application(didRegisterForRemoteWithDeviceToken: notification)
    }

    @objc func application(didFailToRegisterForRemoteNotifications notification: Notification) {
        services.application(didFailToRegisterForRemoteNotifications: notification)
    }

    @objc func application(continueUserActivity notification: Notification) {
        services.application(continueUserActivity: notification)
    }

    @objc func application(willContinueUserActivity notification: Notification) {
        services.application(willContinueUserActivity: notification)
    }

    @objc func application(didFailToContinueUserActivity notification: Notification) {
        services.application(didFailToContinueUserActivity: notification)
    }

    @objc func application(didUpdateUserActivity notification: Notification) {
        services.application(didUpdateUserActivity: notification)
    }

}
