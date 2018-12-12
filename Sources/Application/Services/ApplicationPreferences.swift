//
//  ApplicationPreferences.swift
//  Invoices
//
//  Created by Eric Marchand on 30/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences
import QMobileAPI

class ApplicationPreferences: NSObject {}

private let kUUIDKey = "uuid"
extension ApplicationPreferences: ApplicationService {

    static var instance: ApplicationService = ApplicationPreferences()

    static let settings: PreferencesType = {
        #if DEBUG
        // if compiled without debug, this file will not be used
        let settings: CompositePreferences = [Plist(filename: "Settings.debug") ?? [:], Plist(filename: "Settings") ?? [:]]
        #else
        let settings: DictionaryPreferences = Plist(filename: "Settings") ?? [:]
        #endif
        return settings
    }()

    static let preferences: MutableCompositePreferences = {
        let preferences: MutableCompositePreferences = [Foundation.UserDefaults.standard, ApplicationPreferences.settings, Bundle.main]
        Prephirences.sharedInstance = preferences
        return preferences
    }()

    fileprivate func resetSettings() {
        let userDefaults = Foundation.UserDefaults.standard
        logger.info("Reset settings")
        userDefaults.clearAll()
        userDefaults.synchronize()
        // remove also keychain.
        if Prephirences.Auth.Logout.atStart {
            Prephirences.Auth.Logout.token = APIManager.instance.authToken?.token // keep a token for logout
        }
        let keyChain = KeychainPreferences.sharedInstance
        keyChain.clearAll() // keyChain.lastStatus allow to see that not work
        APIManager.removeAuthToken()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let preferences = ApplicationPreferences.preferences
        var resetDefaults = preferences["resetDefaults"] as? Bool ?? false

        // Fix simulator bug which keep user default for old application
        let userDefaults = Foundation.UserDefaults.standard
        let settings = ApplicationPreferences.settings
        if let expectedUUID = settings[kUUIDKey] as? String {
            if let uuid = userDefaults[kUUIDKey] as? String {
                if uuid != expectedUUID {
                    logger.debug("Application will reset settings because current uuid \(uuid) not equals to expected one \(expectedUUID)")
                    resetDefaults = true // and uuid in pref, but not same as settings file -> reset
                }
            } else {
                logger.debug("No uuid yet. Reset settings and set uuid \(expectedUUID)")
                resetDefaults = true // no uuid in pref -> reset
            }
        } // else no uuid for app, cannot presume

        if resetDefaults {
            resetSettings() // workaround because keychain is not really removed
        }
        // Set new uuid
        userDefaults[kUUIDKey] = settings[kUUIDKey]
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
