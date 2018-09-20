//
//  ApplicationPreferences.swift
//  Invoices
//
//  Created by Eric Marchand on 30/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences

class ApplicationPreferences: NSObject {}

extension ApplicationPreferences: ApplicationService {

    static var instance: ApplicationService = ApplicationPreferences()
    static let uuidKey = "uuid"

    static let preferences: MutableCompositePreferences = {
        #if DEBUG
        // if compiled without debug, this file will not be used
        let settings: CompositePreferences = [Plist(filename: "Settings.debug") ?? [:], Plist(filename: "Settings") ?? [:]]
        #else
        let settings: DictionaryPreferences = Plist(filename: "Settings") ?? [:]
        #endif
        let preferences: MutableCompositePreferences = [Foundation.UserDefaults.standard, settings, Bundle.main]
        Prephirences.sharedInstance = preferences
        return preferences
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let preferences = ApplicationPreferences.preferences
        var resetDefaults = preferences["resetDefaults"] as? Bool ?? false

        // Fix simulator bug which keep user default for old application
        let userDefaults = Foundation.UserDefaults.standard
        let uuidKey = ApplicationPreferences.uuidKey
        let settings = CompositePreferences(preferences.immutableArray)
        if let uuid = userDefaults[uuidKey] as? String, uuid != settings[uuidKey] as? String {
            resetDefaults = true // and uuid in pref, but not same as settings file -> reset
        }
        if resetDefaults {
            logger.info("Reset settings")
            userDefaults.clearAll()
            userDefaults.synchronize()
            // remove also keychain.
            KeychainPreferences.sharedInstance.clearAll()
        }
        userDefaults[uuidKey] = settings[uuidKey]
        userDefaults.synchronize()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       Foundation.UserDefaults.standard.synchronize() // save mutable to disk
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Foundation.UserDefaults.standard.synchronize() // save mutable to disk
    }
}

extension ApplicationService {
    var preferences: MutablePreferencesType {
        return ApplicationPreferences.preferences
    }
    static var preferences: MutablePreferencesType {
        return ApplicationPreferences.preferences
    }
}
