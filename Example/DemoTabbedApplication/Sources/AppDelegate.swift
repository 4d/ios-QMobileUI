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

import QMobileUI

import StyleKit

import RandomKit

import Watchdog

public extension Random {

    static func random() -> Self {

        return self.random(using: &Xoroshiro.default)

    }

}

let logger = XCGLogger(identifier: NSStringFromClass(AppDelegate.self), includeDefaultDestinations: true)

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let threshold = 0.4

    let watchdog = Watchdog(threshold: AppDelegate.threshold) {

        logger.info("👮 Main thread was blocked for " + String(format:"%.2f", AppDelegate.threshold) + "s 👮")

    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // ApplicationServices.instance.register(ApplicationStyleKit.instance)

        DispatchQueue.main.after(15) {

            self.fillModel()

        }

        return true

    }

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

            // TODO alert

            alert(title: "Error when loading model", message: "nothing added to data store queue")

        }

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

    }

}
