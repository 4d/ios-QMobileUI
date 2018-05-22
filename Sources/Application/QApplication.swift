//
//  QApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

// Root class of QMobile application
open class QApplication: UIApplication {

    let services: ApplicationServices = .instance

    public override init() {
        super.init()
        self.initServices()
    }

    // MARK: singleton
    /*
     open override class var shared: QApplication {
     // swiftlint:disable:next force_cast
     return UIApplication.shared as! QApplication
     }
 

    // MARK: override
    open override func sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        let done = super.sendAction(action, to: target, from: sender, for: event)

        return done
    }

    open override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
    }
  */

    func initServices() {
        // Logger
        services.register(ApplicationLogger.instance)

        // Launch option handler
        services.register(ApplicationLaunchOptions.instance)

        // Load preferences
        services.register(ApplicationPreferences.instance)

        // Log all logging step
        services.register(ApplicationStepLogging.instance)

        // Manage authentification
        services.register(ApplicationAuthenticate.instance)

        // Crash Manager
        services.register(ApplicationCrashManager.instance)

        // Load image cache
        services.register(ApplicationImageCache.instance)

        // Load the mobile database
        services.register(ApplicationDataStore.instance)

        // Manage data sync
        services.register(ApplicationDataSync.instance)

        // Load transformers for formatting
        services.register(ApplicationValueTransformers.instance)

        // x-callback-url
        services.register(ApplicationXCallbackURL.instance)
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        services.application(app, open: url, options: options)
        return true
    }

}
