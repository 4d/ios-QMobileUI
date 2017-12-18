//
//  ApplicationService.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/12/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Protocol for an application service. @see UIApplicationDelegate.
@objc public protocol ApplicationService: NSObjectProtocol {

    static var instance: ApplicationService { get }

    @objc optional func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)

    @objc optional func applicationDidEnterBackground(_ application: UIApplication)

    @objc optional func applicationWillEnterForeground(_ application: UIApplication)

    @objc optional func applicationDidBecomeActive(_ application: UIApplication)

    @objc optional func applicationWillResignActive(_ application: UIApplication)

    @objc optional func applicationWillTerminate(_ application: UIApplication)

    @objc optional func applicationDidReceiveMemoryWarning(_ application: UIApplication)

    @objc optional func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)

    @objc optional func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any])
}
