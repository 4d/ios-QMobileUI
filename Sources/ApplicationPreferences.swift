//
//  ApplicationPreferences.swift
//  Invoices
//
//  Created by Eric Marchand on 30/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences

//swiftlint:disable identifier_name
#if DEBUG
let Settings: MutableCompositePreferences = [Plist(filename: "4d.debug") ?? [:], Plist(filename: "4d") ?? [:]]
#else
let Settings: DictionaryPreferences = Plist(filename: "4d") ?? [:]
#endif
let UserDefaults = Foundation.UserDefaults.standard
var MainBundle = Bundle.main
let Preferences: MutableCompositePreferences = [Settings, UserDefaults, MainBundle]

class ApplicationPreferences: NSObject {}

extension ApplicationPreferences: ApplicationService {

    static var instance: ApplicationService = ApplicationPreferences()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        Prephirences.sharedInstance = Preferences
    }

}
