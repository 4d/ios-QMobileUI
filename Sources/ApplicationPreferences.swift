//
//  ApplicationPreferences.swift
//  Invoices
//
//  Created by Eric Marchand on 30/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences

#if DEBUG
let settings: MutableCompositePreferences = [Plist(filename: "Settings.debug") ?? [:], Plist(filename: "Settings") ?? [:]]
#else
let settings: DictionaryPreferences = Plist(filename: "Settings") ?? [:]
#endif
let preferences: MutableCompositePreferences = [Foundation.UserDefaults.standard, settings, Bundle.main]

class ApplicationPreferences: NSObject {}

extension ApplicationPreferences: ApplicationService {

    static var instance: ApplicationService = ApplicationPreferences()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        Prephirences.sharedInstance = preferences
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       Foundation.UserDefaults.standard.synchronize() // save mutable to disk
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Foundation.UserDefaults.standard.synchronize() // save mutable to disk
    }
}
