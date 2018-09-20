//
//  ApplicationServicesTests.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import XCTest
@testable import QMobileUI

class ApplicationServicesTests: XCTestCase {
    
 
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func _testServiceReceiveNotifications() {
        // TODO make an UI test target to have an application
        let services = ApplicationServices.instance
        let service = ApplicationServiceMock.test
        service.clear()
        services.register(service)
        defer {
            service.clear()
            //services.unregister(service)
        }

        let center = NotificationCenter.default

        let names: [Notification.Name] = [UIApplication.didFinishLaunchingNotification, UIApplication.didFinishLaunchingNotification,
                                          UIApplication.didEnterBackgroundNotification, UIApplication.willEnterForegroundNotification,
                                          UIApplication.didBecomeActiveNotification, UIApplication.willResignActiveNotification,
                                          UIApplication.didReceiveMemoryWarningNotification, UIApplication.willTerminateNotification,
                                          UIApplication.didRegisterForRemoteWithDeviceTokenNotification, UIApplication.openUrlWithOptionsNotification]
        let application: UIApplication = UIApplication.shared // XXX unable to mock application... do ui tests?
        for name in names {
            var userInfo: [AnyHashable : Any]? = nil
            if name == UIApplication.didRegisterForRemoteWithDeviceTokenNotification {
                userInfo = [ApplicationServiceUserInfoKey.deviceToken: Data()]
                
            } else if name == UIApplication.openUrlWithOptionsNotification {
                userInfo = [ApplicationServiceUserInfoKey.openUrl: URL(string: "http://example.com")!, ApplicationServiceUserInfoKey.openUrlOptions: [UIApplication.OpenURLOptionsKey : Any]()]
            }
            let notification = Notification(name: name, object: application,  userInfo: userInfo)
            center.post(notification)
        }

        XCTAssertEqual(service.receives.count, names.count)
    }

}

// MOCK
class ApplicationServiceMock: NSObject, ApplicationService {
    static var instance: ApplicationService = ApplicationServiceMock()
    static var test: ApplicationServiceMock = ApplicationServiceMock()
    
    open var receives: Set<Notification.Name> = Set<Notification.Name>()
    
    func clear() {
        receives.removeAll()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        receives.insert(UIApplication.didFinishLaunchingNotification)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        receives.insert(UIApplication.didEnterBackgroundNotification)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        receives.insert(UIApplication.willEnterForegroundNotification)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        receives.insert(UIApplication.didBecomeActiveNotification)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        receives.insert(UIApplication.willResignActiveNotification)
    }
    
    func applicationWillTerminate(_ UIApplicationWillTerminate: UIApplication) {
        receives.insert(UIApplication.willTerminateNotification)
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        receives.insert(UIApplication.didReceiveMemoryWarningNotification)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        receives.insert(UIApplication.didRegisterForRemoteWithDeviceTokenNotification)
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        receives.insert(UIApplication.openUrlWithOptionsNotification)
    }
    
}
 
