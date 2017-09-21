//
//  AppDelegate.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import XCGLogger
import QMobileDataStore
import QMobileDataSync
import QMobileUI
import QMobileAPI
import StyleKit
import RandomKit
import Watchdog
import NSLogger
import XCGLoggerNSLoggerConnector
import LinearProgressBarMaterial
import SwiftMessages
import Moya


class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var listeners: [NSObjectProtocol] = []
    var cancellables: [Cancellable] = []

    static let threshold = 0.4

    var watchdog: Watchdog?
    let linearBar: LinearProgressBar = LinearProgressBar()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        LoggerSetOptions(LoggerGetDefaultLogger(), UInt32( kLoggerOption_BufferLogsUntilConnection | kLoggerOption_BrowseBonjour | kLoggerOption_BrowseOnlyLocalDomain ))
        LoggerStart(LoggerGetDefaultLogger())
        loggerapp.add(destination: XCGNSLoggerLogDestination(owner: loggerapp, identifier: "nslogger.identifier"))
        loggerapp.add(destination: AppleSystemLogDestination(owner: loggerapp, identifier: "apple"))

        watchdog = Watchdog(threshold: AppDelegate.threshold) {
            loggerapp.info("👮 Main thread was blocked for " + String(format:"%.2f", AppDelegate.threshold) + "s 👮", userInfo:  Domain.monitor | Dev.eric | Tag.demo)
        }

        listeners.append(dataStore.onLoad { notif in
            loggerapp.info("DS load \(notif)", userInfo: Domain.test | Dev.eric | Tag.demo | Image.done)
        })
        listeners.append(dataStore.onSave { notif in
            loggerapp.info("DS save \(notif)", userInfo: Domain.test | Dev.eric | Tag.demo)
        })
        listeners.append(dataStore.onDrop { notif in
            loggerapp.info("DS drop \(notif)", userInfo: Domain.test | Dev.eric | Tag.demo)
        })


        // swiftlint2:disable:next discarded_notification_center_observer
        listeners.append(NotificationCenter.default.addObserver(forName: .dataSyncBegin, object: nil, queue: .main) { _ in
            self.linearBar.startAnimation()
        })
        // swiftlint2:disable:next discarded_notification_center_observer
        listeners.append(NotificationCenter.default.addObserver(forName: .dataSyncSuccess, object: nil, queue: .main) { _ in
            self.linearBar.stopAnimation()
        })
        // swiftlint2:disable:next discarded_notification_center_observer
        listeners.append(NotificationCenter.default.addObserver(forName: .dataSyncFailed, object: nil, queue: .main) { _ in
            self.linearBar.stopAnimation()
        })

        /*
        DataSync.instance.rest.plugins += [PreparePlugin { request, _ in
            DispatchQueue.main.async {
            }
            return request
            }]

        DataSync.instance.rest.plugins += [ReceivePlugin { _, _ in
         DispatchQueue.main.async {
         }
         }]*/

        APIManager.reachability { status in
            switch status {
            case .unknown:
                SwiftMessages.displayError(title: "unknown", message: "unknown m")

            case .notReachable:
                SwiftMessages.displayWarning("You seems to be offline")

            case .reachable(let type) :
                switch type {
                case .ethernetOrWiFi:
                    print("wifi")
                case .wwan:
                    print("wwan")
                }

                //SwiftMessages.displayConfirmation("Data updated")
            }
            }.flatMap {
                cancellables.append($0)
        }

        return true

    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicatinWillTerminate(_ application: UIApplication) {
        for listener in listeners {
            dataStore.unobserve(listener)
        }
    }
/*
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let services = ApplicationServices.instance
        services.application(app, open: url, options: options)
        return true
    }*/
}
