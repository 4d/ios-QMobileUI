//
//  AppDelegate+Services.swift
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___
//  ___COPYRIGHT___

import Foundation
import UIKit

// Allow applications services to register to OpenURL(application url scheme) or DeviceToken remote notification
extension AppDelegate {

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        type(of: self).application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return type(of: self).application(app, open: url, options: options)
    }

}