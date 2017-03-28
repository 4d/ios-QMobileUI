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

let logger = XCGLogger(identifier: NSStringFromClass(AppDelegate.self), includeDefaultDestinations: true)


class BoolTransformer: ValueTransformer {
    
    open override func transformedValue(_ value: Any?) -> Any?{
        guard let value = value else {
            return nil
        }
        return String(describing: value)
    }

    
    open override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? String else {
            return nil
        }
        return Bool(value)
    }

}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        sharedDataStore.load { [unowned self] result in
            logger.info("loading data store \(result)")
            
            self.fillModel()
        }
        
        class BoolTransformer: ValueTransformer {
            
            open override func transformedValue(_ value: Any?) -> Any?{
                guard let value = value else {
                    return nil
                }
                return String(describing: value)
            }
            
            
            open override func reverseTransformedValue(_ value: Any?) -> Any? {
                guard let value = value as? String else {
                    return nil
                }
                return Bool(value)
            }
            
        }
        ValueTransformer.setValueTransformer(BoolTransformer(), forName: NSValueTransformerName("BoolToString"))
        
        
        
        if let styleFile = Bundle.main.url(forResource: "style", withExtension: "json") {

            StyleKit(fileUrl: styleFile, logLevel: .debug)?.apply()

        }
        
        UITabBar.appearance().barStyle = .black
        
        return true
    }
    
    func fillModel() {
        self.testadd(20000)
    }
    
    func testadd(_ max: Int) {
        let dataStore = sharedDataStore
        let added = dataStore.perform(.background) { context, save in
            for i in 0...max {
                let record = context.newRecord(table: "Entity")
                record["string"] = "string \(i) test"
                record["bool"] = i % 2 == 0
                record["integer"] = i

                record["category"] = "\(i % 10)"

                if i % 10000 == 0 {
                    do {
                        try save()
                    } catch {
                        Alert(title: "Error when loading model", message: "\(error)")
                    }
                }
            }
            do {
                try save()
            } catch {
                Alert(title: "Error when loading model", message: "\(error)")
            }
        }
        if !added {
            // TODO alert
            Alert(title: "Error when loading model", message: "nothing added to data store queue")
        }

    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        sharedDataStore.save { result in
            logger.info("\(result)")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        sharedDataStore.save { result in
            logger.info("\(result)")
        }
    }

}
