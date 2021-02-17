//
//  ApplicationPreferences.swift
//  Invoices
//
//  Created by Eric Marchand on 30/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences
import QMobileAPI

class ApplicationPreferences: NSObject {}

private let kUUIDKey = "uuid"

private let kFullVersion = "kFullVersion"
private let kIDEVersion = "kIDEVersion"
private let kSDKVersion = "kSDKVersion"

extension ApplicationPreferences: ApplicationService {

    static var instance: ApplicationService = ApplicationPreferences()

    static let settings: PreferencesType = {
        #if DEBUG
        // if compiled without debug, this file will not be used
        let thesettings: CompositePreferences = [Plist(filename: "Settings.debug") ?? [:], Plist(filename: "Settings") ?? [:]]
        #else
        let thesettings: DictionaryPreferences = Plist(filename: "Settings") ?? [:]
        #endif
        return thesettings
    }()

    static let preferences: MutableCompositePreferences = {
        let preferences: MutableCompositePreferences = [Foundation.UserDefaults.standard, ApplicationPreferences.settings, Bundle.main]
        Prephirences.sharedInstance = preferences
        return preferences
    }()

    static func resetSettings() {
        let userDefaults = Foundation.UserDefaults.standard
        logger.info("Reset settings")
        userDefaults.clearAll()
        userDefaults.synchronize()
        // remove also keychain.
        if Prephirences.Auth.Logout.atStart {
            Prephirences.Auth.Logout.token = APIManager.instance.authToken?.token // keep a token for logout
        }
        APIManager.instance.authToken = nil
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
            ApplicationPreferences.resetSettings() // workaround because keychain is not really removed
        }
        // Set new uuid
        userDefaults[kUUIDKey] = settings[kUUIDKey]

        // Transfert some information to UserDefaults from Info.plist for settting bundle
        if let info = preferences["4D"] as? [String: String] {
            if let ide = info["ide"], let build = info["build"] {
                userDefaults[kIDEVersion] = "\(ide).\(build)"
            }
            if let sdk = info["sdk"], let frameworks = sdk.split(separator: "@").last {
                userDefaults[kSDKVersion] = "\(frameworks)"
            }
        }
        userDefaults[kFullVersion] = UIApplication.build

        // Finish
        userDefaults.synchronize() // XXX maybe now useless

        ClassStore.register(ImageUploadOperationInfo.self)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Foundation.UserDefaults.standard.synchronize() // save mutable to disk // XXX maybe now useless
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Foundation.UserDefaults.standard.synchronize() // save mutable to disk // XXX maybe now useless
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
