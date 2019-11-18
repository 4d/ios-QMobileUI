//
//  ApplicationStepLogging.swift
//  Invoices
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import XCGLogger

/// Log the step of application launching
class ApplicationStepLogging: NSObject {

    var level: XCGLogger.Level

    init(level: XCGLogger.Level) {
        self.level = level
    }

}

extension ApplicationStepLogging: ApplicationService {

    static var instance: ApplicationService = ApplicationStepLogging(level: .debug)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        logger.log(level, "\(#function)")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        logger.log(level, "\(#function)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        logger.log(level, "\(#function)")
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        logger.log(level, "\(#function)")
    }

}
