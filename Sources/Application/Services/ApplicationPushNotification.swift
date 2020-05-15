//
//  ApplicationPushNotificationService.swift
//  QMobileUI
//
//  Created by Quentin Marciset on 08/04/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import UserNotifications

import Prephirences
import QMobileAPI

class ApplicationPushNotification: NSObject {

    var apiManagerObserver: NSObjectProtocol?

}

extension ApplicationPushNotification: ApplicationService {

    static var instance: ApplicationService = ApplicationPushNotification()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {

        UNUserNotificationCenter.current().delegate = self

        if let pushNotificationsEnabled = Prephirences.sharedInstance["pushNotification"] as? Bool, pushNotificationsEnabled {
            startMonitoringAPIManager()
        }
        // Check if app was launched from notification popup (ie. app was in background or not running)
        let notificationOption = launchOptions?[.remoteNotification]
        if let notification = notificationOption as? [String: AnyObject], let aps = notification["aps"] as? [String: AnyObject] {
            // A notification was received. Use data from 'aps' dictionary here
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
    }

    /// Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        sendDeviceTokenToServer(deviceToken: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.warning("Failed to register: \(error)")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        stopMonitoringAPIManager()
    }
}

extension ApplicationPushNotification {

    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                logger.info("Notification permission granted? \(granted)")
                guard granted else {
                    logger.debug("Push Notifications permission is not granted")
                    return
                }

                self?.setActionableNotification()

                /// Exclusively for testing on simulator
                if Device.current.isSimulator {
                    let simulatorDeviceToken = UIDevice.current.simulatorID  ?? "booted"
                    logger.info("Device token cannot be fetched on a simulator. Use simulator id \(simulatorDeviceToken)")
                    self?.sendDeviceTokenToServer(deviceToken: simulatorDeviceToken)
                } else {
                    self?.getNotificationSettings()
                }
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                logger.debug("Push Notifications permission is not granted")
                return
            }
            logger.debug("Push Notifications permission is granted")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func sendDeviceTokenToServer(deviceToken: String) {
        logger.info("Will send deviceToken to server")
        _ = APIManager.instance.sendDeviceToken(deviceToken, callbackQueue: .background) { (result) in
            switch result {
            case .success(let value):
                logger.info("DeviceToken successfully sent to server")
                logger.debug("DeviceToken request response: \(value)")
            case .failure(let error):
                logger.info("An error occurred while sending deviceToken to server")
                logger.debug("DeviceToken request error: \(error)")
            }
        }
    }

    func setActionableNotification() {
        let customAction = UNNotificationAction(identifier: Identifiers.customAction, title: "My custom action title", options: [.foreground])
        let customCategory = UNNotificationCategory(identifier: Identifiers.customCategory, actions: [customAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([customCategory])
    }
}

/// Handling notification actions event
extension ApplicationPushNotification: UNUserNotificationCenterDelegate {

    enum Identifiers {
        static let customAction = "MY_CUSTOM_ACTION_IDENTIFIER"
        static let customCategory = "MY_CUSTOM_CATEGORY_IDENTIFIER"
    }

    /// Callback method when a notification alert is clicked
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo

        // Get notification content
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            // Check the action identifier
            if response.actionIdentifier == Identifiers.customAction {
                // Add custom behavior for your action 'customAction'
            }
        }

        completionHandler()
    }

    /// Notification signal is received while app is in foreground. This callback let you decide if you want to display an alert or just a badge, a sound, etc.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo

        // Get notification content
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            // Check the action identifier
            if let category = aps["category"] as? String, category == Identifiers.customAction {
                // Add custom behavior for your action 'customAction'
            }
        }
        // completionHandler([.badge, .sound])
        completionHandler([.alert, .badge, .sound])
    }
}

/// Being notified on successful login to start registering for push notifications
extension ApplicationPushNotification {

    fileprivate func startMonitoringAPIManager() {
        apiManagerObserver = APIManager.observe(APIManager.loginSuccess) { _ in
            self.registerForPushNotifications()
        }
    }

    fileprivate func stopMonitoringAPIManager() {
        if let apiManagerObserver = apiManagerObserver {
            APIManager.unobserve(apiManagerObserver)
        }
        apiManagerObserver = nil
    }
}