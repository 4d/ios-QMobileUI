//
//  QApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// Root class of QMobile application
open class QApplication: UIApplication {

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
        let services = ApplicationServices.instance

        // Logger
        services.register(ApplicationLogger.instance)

        // Load preferences
        services.register(ApplicationPreferences.instance)

        // Log all logging step
        services.register(ApplicationStepLogging.instance)

        // Load the mobile database
        services.register(ApplicationLoadDataStore.instance)

        // Load transformers for formatting
        services.register(ApplicationValueTransformers.instance)
    }

}
