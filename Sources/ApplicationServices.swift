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

    public private(set) var services: [ApplicationService] = []

    public class var instance: ApplicationServices { return applicationServices }

    public func register(_ service: ApplicationService) {
        services.append(service)
    }
    public func unregister(_ service: ApplicationService) {
        services.delete(service)
    }
    // prevent external init ie. singleton
    fileprivate init() {}

}

// launch setup immediately
private let applicationServices = ApplicationServices().setup()
fileprivate extension ApplicationServices {

    fileprivate func setup() -> Self {
        setupObservers()
        return self
    }

    fileprivate func setupObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(application(didFinishLaunching:)), name: .UIApplicationDidFinishLaunching, object: nil)
        center.addObserver(self, selector: #selector(application(didEnterBackground:)), name: .UIApplicationDidEnterBackground, object: nil)
        center.addObserver(self, selector: #selector(application(willEnterForeground:)), name: .UIApplicationWillEnterForeground, object: nil)
        center.addObserver(self, selector: #selector(application(didBecomeActive:)), name: .UIApplicationDidBecomeActive, object: nil)
        center.addObserver(self, selector: #selector(application(willResignActive:)), name: .UIApplicationWillResignActive, object: nil)
        center.addObserver(self, selector: #selector(application(didReceiveMemoryWarning:)), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
        center.addObserver(self, selector: #selector(application(willTerminate:)), name: .UIApplicationWillTerminate, object: nil)
        center.addObserver(self, selector: #selector(application(didRegisterForRemoteWithDeviceToken:)), name: .UIApplicationDidRegisterForRemoteWithDeviceToken, object: nil)
        center.addObserver(self, selector: #selector(application(openUrlWithOptions:)), name: .UIApplicationOpenUrlWithOptions, object: nil)
    }

}

extension ApplicationServices {

    /// Could call this function to easily register application services
    public func then(_ block: (_ services: ApplicationServices) -> Void) -> Self {
        block(self)
        return self
    }

}

/// Protocol for an application service. @see UIApplicationDelegate.
@objc public protocol ApplicationService: NSObjectProtocol {

    static var instance: ApplicationService { get }

    @objc optional func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?)

    @objc optional func applicationDidEnterBackground(_ application: UIApplication)

    @objc optional func applicationWillEnterForeground(_ application: UIApplication)

    @objc optional func applicationDidBecomeActive(_ application: UIApplication)

    @objc optional func applicationWillResignActive(_ application: UIApplication)

    @objc optional func applicationWillTerminate(_ application: UIApplication)

    @objc optional func applicationDidReceiveMemoryWarning(_ application: UIApplication)

    @objc optional func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)

    @objc optional func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
}

// Special notifications
struct ApplicationServiceUserInfoKey {
    static let openUrl = "__openUrl"
    static let openUrlOptions = "__openUrlOptions"
    static let deviceToken = "__deviceToken"
}

extension Notification.Name {

    static let UIApplicationOpenUrlWithOptions: Notification.Name = .init("UIApplicationOpenUrlWithOptions")
    //swiftlint:disable:next identifier_name
    static let UIApplicationDidRegisterForRemoteWithDeviceToken: NSNotification.Name = .init("UIApplicationDidRegisterForRemoteWithDeviceToken")

}
// create missing notifications
public extension UIApplicationDelegate {

    static func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .UIApplicationDidRegisterForRemoteWithDeviceToken, object: application, userInfo: [ApplicationServiceUserInfoKey.deviceToken: deviceToken])
    }

    /*func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        type(of: self).application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }*/

    static func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: .UIApplicationOpenUrlWithOptions, object: app, userInfo: [ApplicationServiceUserInfoKey.openUrl: url, ApplicationServiceUserInfoKey.openUrlOptions: options])
        return true
    }

    /*func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return type(of: self).application(app, open: url, options: options)
    }*/

}

// Remap notifications to all services
fileprivate extension Notification {
    var application: UIApplication {
        //swiftlint:disable:next force_cast
        return self.object as! UIApplication
    }
}

private extension ApplicationServices {

    @objc func application(didFinishLaunching notification: Notification) {
        services.forEach { service in
            service.application?(notification.application, didFinishLaunchingWithOptions: notification.userInfo as? [UIApplicationLaunchOptionsKey : Any])
        }
    }

    @objc func application(didEnterBackground notification: Notification) {
        services.forEach { service in
            service.applicationDidEnterBackground?(notification.application)
        }
    }

    @objc func application(willEnterForeground notification: Notification) {
        services.forEach { service in
            service.applicationWillEnterForeground?(notification.application)
        }
    }

    @objc func application(didBecomeActive notification: Notification) {
        services.forEach { service in
            service.applicationDidBecomeActive?(notification.application)
        }
    }

    @objc func application(willResignActive notification: Notification) {
        services.forEach { service in
            service.applicationWillResignActive?(notification.application)
        }
    }

    @objc func application(willTerminate notification: Notification) {
        services.forEach { service in
            service.applicationWillTerminate?(notification.application)
        }
    }

    @objc func application(didReceiveMemoryWarning notification: Notification) {
        services.forEach { service in
            service.applicationDidReceiveMemoryWarning?(notification.application)
        }
    }

    @objc func application(openUrlWithOptions notification: Notification) {
        guard let url = notification.userInfo?[ApplicationServiceUserInfoKey.openUrl] as? URL,
            let options = notification.userInfo?[ApplicationServiceUserInfoKey.openUrlOptions] as? [UIApplicationOpenURLOptionsKey : Any] else {
                return
        }
        services.forEach { service in
            service.application?(notification.application, open: url, options: options)
        }
    }

    @objc func application(didRegisterForRemoteWithDeviceToken notification: Notification) {
        if let data = notification.userInfo?[ApplicationServiceUserInfoKey.deviceToken] as? Data {
            services.forEach { service in
                service.application?(notification.application, didRegisterForRemoteNotificationsWithDeviceToken: data)
            }
        }
    }

}
