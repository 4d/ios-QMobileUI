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

public extension Random {

    static func random() -> Self {
        return self.random(using: &Xoroshiro.default)
    }

}

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var listeners: [NSObjectProtocol] = []

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

        // ApplicationServices.instance.register(ApplicationStyleKit.instance)
        DispatchQueue.main.after(15) {
            self.fillModel()
        }

        // swiftlint:disable:next discarded_notification_center_observer
        listeners.append(NotificationCenter.default.addObserver(forName: .dataSyncBegin, object: nil, queue: .main) { _ in
            self.linearBar.startAnimation()
        })
        // swiftlint:disable:next discarded_notification_center_observer
        listeners.append(NotificationCenter.default.addObserver(forName: .dataSyncSuccess, object: nil, queue: .main) { _ in
            self.linearBar.stopAnimation()
        })
        // swiftlint:disable:next discarded_notification_center_observer
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

    func applicationWillTerminate(_ application: UIApplication) {
        for listener in listeners {
            dataStore.unobserve(listener)
        }
    }
 
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let services = ApplicationServices.instance
        services.application(app, open: url, options: options)
        return true
    }
}

extension AppDelegate {

    func fillModel() {
      // self.testadd(20000)
    }

    func testadd(_ max: Int) {
        let added = dataStore.perform(.background) { context, save in
            for i in 0...max {
                let date = Date()

                let record = context.create(in: "Entity")

                record?["string"] = UUID.init().uuidString
                record?["bool"] = i % 2 == 0
                record?["integer"] = i
                record?["date"] = date
                record?["time"] = date.timeIntervalSince1970
                record?["alpha"] = String.random()
                record?["blob"] = Data()
                record?["bool"] = Bool.random()
                record?["category"] = String.random()
                record?["date"] = Date()
                record?["float"] = Float.random()
                record?["iD"] = Int32.random()
                record?["image"] = Data()
                record?["integer"] = Int16.random()
                record?["integer64"] = Int64.random()
                record?["longInteger"] = Int32.random()
                record?["object"] = [:]
                record?["real"] = Double.random()
                record?["text"] = String.random()
                record?["time"] = Int64.random()
                record?["category"] = "\(i % 10)"

                if i % 10000 == 0 {
                    do {
                        try save()
                    } catch {
                        alert(title: "Error when loading model", message: "\(error)")
                    }
                }
            }

            do {
                try save()
            } catch {
                alert(title: "Error when loading model", message: "\(error)")
            }
        }

        if !added {
            alert(title: "Error when loading model", message: "nothing added to data store queue")
        }
    }

}
