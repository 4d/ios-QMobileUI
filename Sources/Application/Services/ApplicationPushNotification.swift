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
import SwiftMessages
import DeviceKit

import QMobileAPI

class ApplicationPushNotification: NSObject {

    var apiManagerObservers: [NSObjectProtocol] = []
    var launchFromNotification = false

}

extension ApplicationPushNotification: ApplicationService {

    static var instance: ApplicationService = ApplicationPushNotification()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {

        UNUserNotificationCenter.current().delegate = self

        if let pushNotificationsEnabled = Prephirences.sharedInstance["pushNotification"] as? Bool, pushNotificationsEnabled {
            startLoginObserver()
            startLogoutObserver()
            getNotificationSettings()
        }
        // Check if app was launched from notification popup (ie. app was in background or not running)
        let notificationOption = launchOptions?[.remoteNotification]
        if let notification = notificationOption as? [String: AnyObject], let aps = notification["aps"] as? [String: AnyObject] {
            logger.info("App launch with notification \(aps)")
            launchFromNotification = true
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
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
                logger.info("Notification permission granted? \(granted)")
                guard granted else {
                    logger.debug("Push Notifications permission is not granted")
                    return
                }
                if let error = error {
                    logger.warning("An error occurred while requesting remote notifications authorization : \(error)")
                }
                guard let this = self else {
                    logger.warning("Cannot retain in memory push notification authorization request")
                    return
                }
                this.getNotificationSettings()
        }
    }

    func unregisterForPushNotifications() {
        logger.info("Will unregister for remote notifications")
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    /// request notification setting
    func getNotificationSettings() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                logger.debug("Push Notifications permission is not granted")
                return
            }
            logger.debug("Push Notifications permission is granted")
            self.registerCategory()

            /// Exclusively for testing on simulator
            if Device.current.isSimulatorCase {

                let simulatorDeviceToken = UIDevice.current.simulatorID  ?? "booted"
                logger.info("Device token cannot be fetched on a simulator. Use simulator id \(simulatorDeviceToken)")
                self.sendDeviceTokenToServer(deviceToken: simulatorDeviceToken)

            } else {

                logger.info("Will register for remote notifications")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
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

    func registerCategory() {
        let notificationCenter = UNUserNotificationCenter.current()

        let categories: [UNNotificationCategory] = Action.allCases.compactMap({ $0.unNotificationCategory})
        if !categories.isEmpty {
            notificationCenter.setNotificationCategories(Set(categories))
        }
    }
}

/// Handling notification actions event
extension ApplicationPushNotification: UNUserNotificationCenterDelegate {

    /// Enumeration of available action for notification
    enum Action: String, CaseIterable {
        case `default` = "com.apple.UNNotificationDefaultActionIdentifier" // UNNotificationDefaultActionIdentifie, default click on notif
        /*case dismiss = "com.apple.UNNotificationDismissActionIdentifier" // UNNotificationDismissActionIdentifier*/
        // here could add enum case to provide action button on notification using "category" mecanism

        fileprivate init?(_ response: UNNotificationResponse) {
            self.init(rawValue: response.actionIdentifier)
        }

        private var title: String {
            switch self {
            case .default:
                return ""
            /*case .dismiss:
                return "Dismiss"//LOCALIZED*/
            }
        }

        private var category: String {
            switch self {
            case .default:
                return "OPEN_FORM"
            /*case .dismiss:
                return "Dismiss"*/
            }
        }

        private var unNotificationActions: [UNNotificationAction]? {
            switch self {
            /*case .open:
                return [UNNotificationAction(identifier: self.rawValue, title: self.title, options: [.foreground])]*/
            default:
                return nil
            }
        }

        var unNotificationCategory: UNNotificationCategory? {
            guard let unNotificationActions = unNotificationActions, !unNotificationActions.isEmpty else {
                return nil
            }
            return UNNotificationCategory(identifier: self.category, actions: unNotificationActions, intentIdentifiers: [], options: [])
        }

        fileprivate func executeDefault(_ userInfo: [AnyHashable: Any], withCompletionHandler completionHandler: @escaping () -> Void) {
            if let dataSynchro = userInfo["dataSynchro"] as? Bool, dataSynchro {
                logger.info("Data synchronization requested by push notification")

                let dataSyncInstance = ApplicationDataSync.instance.dataSync
                let dataStore = dataSyncInstance.dataStore // CLEAN better way to get it(singleton is ...)
                if !dataStore.isLoaded {
                    logger.info("Data store is not loaded yet, postpone data synchronization by push notification")
                    // bug do not manipulate too soon the datastore or two load are done (section critic is not locked?)
                    DispatchQueue.main.after(2) { // alternative: wait data store load event?  DataStoreFactory.observe(.dataStoreLoaded) { _ in } (issue possible, loaded just after register, even not received
                        self.executeDefault(userInfo, withCompletionHandler: completionHandler)
                    }
                    return
                }
                if let deepLink = DeepLink.from(userInfo),
                   case DeepLink.record(let tableName, let primaryKeyValue) = deepLink,
                   let table = dataSyncInstance.tables.filter({$0.name == tableName}).first,
                   let tableInfo = dataSyncInstance.tablesInfoByTable[table],
                   let matchingPredicated = tableInfo.primaryKeyPredicate(value: primaryKeyValue) {

                    let willPerform = dataStore.perform(.foreground) { context in
                        let records = try? context.get(in: tableInfo, matching: matchingPredicated) ?? []
                        let notExists = records.isEmpty
                        let alwaysRefresh = true
                        if notExists || alwaysRefresh {
                           // let loading = UIApplication.topViewController?.showLoading()
                            SwiftMessages.loading()
                            _ = dataSyncInstance.sync(operation: .record(tableName, primaryKeyValue), in: context.type) { recordResult in
                                // TODO #123012 if notExists and failed, -> error cannot display
                                logger.debug("Record \(deepLink) synchronised after push notfification: \(recordResult)")
                                DispatchQueue.main.after(1) { // XXX instead of 1, check if time already superior to one
                                    SwiftMessages.hide()
                                    if case .failure(let error) = recordResult {
                                        switch error {
                                        case .apiError(let apiError):
                                            SwiftMessages.showError(ActionRequest.Error(apiError)) // CLEAN have a central method for api error
                                        default:
                                            break
                                        }
                                    }
                                }
                                DispatchQueue.userInitiated.async {
                                    executeDefault0(userInfo, withCompletionHandler: completionHandler)
                                    _ = dataSync { _ in } // try fullscreen event if first one failed?
                                }
                            }
                        } else {
                            executeDefault0(userInfo, withCompletionHandler: completionHandler)
                            _ = dataSync { _ in }
                        }
                    }
                    if !willPerform {
                        logger.info("Data store not ready to be requested by a push notification")
                        // TODO relaunch later or on data store load event
                        DispatchQueue.userInitiated.after(10) {
                            executeDefault(userInfo, withCompletionHandler: completionHandler)
                        }
                    }
                } else {
                    executeDefault0(userInfo, withCompletionHandler: completionHandler)
                    _ = dataSync { _ in }
                }
            } else {
                executeDefault0(userInfo, withCompletionHandler: completionHandler)
            }
        }

        fileprivate func executeDefault0(_ userInfo: [AnyHashable: Any], withCompletionHandler completionHandler: @escaping () -> Void) {
            if let deepLink = DeepLink.from(userInfo) {
                logger.debug("Deep link notification \(userInfo): \(deepLink)")
                foreground {
                    ApplicationCoordinator.open(deepLink) { result in
                        logger.debug("Deep link \(deepLink) opened with result \(result)")
                        completionHandler()
                    }
                }
            } else {
                logger.debug("No deep link with \(userInfo)")
                completionHandler()
            }
        }

        fileprivate func execute(_ userInfo: [AnyHashable: Any], withCompletionHandler completionHandler: @escaping () -> Void) {
            switch self {
            case .default:
                executeDefault(userInfo, withCompletionHandler: completionHandler)
            }
        }
    }

    /// Callback method when a notification alert is clicked
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Get notification content
        // check action to execute
        if let action = Action(response) {
            logger.debug("Application state when receive notification: \(response.notification) \(UIApplication.shared.applicationState.rawValue). \(launchFromNotification)")
            let userInfo = response.notification.request.content.userInfo
            logger.verbose("Extracted userInfo: \(response.notification.request.content.userInfo)")
            if launchFromNotification {
                DispatchQueue.userInitiated.after(2) {
                    action.execute(userInfo, withCompletionHandler: completionHandler)
                }
            } else {
                action.execute(userInfo, withCompletionHandler: completionHandler)
            }
        } else {
            completionHandler()
        }
    }

    /// Notification signal is received while app is in foreground. This callback let you decide if you want to display an alert or just a badge, a sound, etc.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
}

/// Being notified on login / logout to start / stop registering for push notifications
extension ApplicationPushNotification {

    fileprivate func startLoginObserver() {
        let loginObserver = APIManager.observe(APIManager.loginSuccess) { _ in
            self.registerForPushNotifications()
        }
        apiManagerObservers += [loginObserver]
    }

    fileprivate func startLogoutObserver() {
        let logoutObserver = APIManager.observe(APIManager.logout) { _ in
            self.unregisterForPushNotifications()
        }
        apiManagerObservers += [logoutObserver]
    }

    fileprivate func stopMonitoringAPIManager() {
        for observer in apiManagerObservers {
            APIManager.unobserve(observer)
        }
    }
}
