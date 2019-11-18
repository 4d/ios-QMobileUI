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

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {}

    public func applicationDidEnterBackground(_ application: UIApplication) {}

    public func applicationWillEnterForeground(_ application: UIApplication) {}

    public func applicationDidBecomeActive(_ application: UIApplication) {}

    public func applicationWillResignActive(_ application: UIApplication) {}

    public func applicationWillTerminate(_ application: UIApplication) {}

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {}

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {}

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {}

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool { return false }

    public func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool { return false }

    public func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {}

    public func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {}

}
