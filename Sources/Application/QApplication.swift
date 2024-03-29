//
//  QApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences
import QMobileAPI

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

     */

    var shakeEvent: UIEvent?

    open override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        if event.subtype == .motionShake {
            let center = NotificationCenter.default
            if shakeEvent == nil {
                shakeEvent = event
                center.post(name: .motionShakeBegin, object: event)
            } else {
                shakeEvent = nil // maybe cancelled
                center.post(name: .motionShakeEnd, object: event)
            }
        }
    }

    func initServices() {
        // Logger
        services.register(ApplicationLogger.instance)

        // Load preferences
        services.register(ApplicationPreferences.instance)

        // Log all logging step
        services.register(ApplicationStepLogging.instance)

        // Check reachability of network
        services.register(ApplicationReachability.instance)

        // Crash Manager
        services.register(ApplicationCrashManager.instance)

        // Coordinator
        services.register(ApplicationCoordinator.instance)

        // Manage authentification
        services.register(ApplicationAuthenticate.instance)

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

        // Feedback
        services.register(ApplicationFeedback.instance)

        // Push notifications
        services.register(ApplicationPushNotification.instance)

        // custom services?
        let customServices = ApplicationPreferences.instance.preferences.stringArray(forKey: "application.services") ?? []
        for service in customServices {
            if let cls = NSClassFromString(service) {
                if let value = cls.value(forKey: "instance") as? ApplicationService {
                    services.register(value)
                } else {
                    logger.warning("Not a valid service \(service). Must have a static 'instance' of type `ApplicationService`")
                }
            } else {
                logger.warning("Cannot load service \(service) ")
            }
        }
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        services.application(app, open: url, options: options)
        return true
    }

    // MARK: Get application information

    static var applicationInformation: [String: String] {
        var information = [String: String]()

        let bundle = Bundle.main
        // Application
        information["CFBundleShortVersionString"] =  bundle[.CFBundleShortVersionString] as? String ?? ""
        information["CFBundleIdentifier"] = bundle[.CFBundleIdentifier] as? String ?? ""
        information["CFBundleName"] = bundle[.CFBundleName] as? String ?? ""

        // Team id
        information["AppIdentifierPrefix"] = bundle["AppIdentifierPrefix"] as? String ?? ""

        // OS
        information["DTPlatformVersion"] = bundle[.DTPlatformVersion] as? String ?? "" // XXX UIDevice.current.systemVersion ??

        // Device
        let device = Device.current
        let realDevice = device.realDevice
        information["device.description"] = realDevice.description
        if device.isSimulatorCase {
            information["device.simulator"] = "YES"
        }
        let versions = Bundle.main["4D"] as? [String: String] ?? [:]
        information["build"] = versions["build"]
        information["component"] = versions["component"]
        information["ide"] = versions["ide"]
        information["sdk"] = versions["sdk"]
        if let uuid = Prephirences.sharedInstance["uuid"] as? String {
            information["uuid"] = uuid
        }
        return information
    }
}

extension Notification.Name {
    static let motionShakeBegin = Notification.Name(rawValue: "motionShakeBegin")
    static let motionShakeEnd = Notification.Name(rawValue: "motionShakeEnd")
}

/*
 // other way to detect
public extension UIWindow {

    open override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard let event = event else {
            return
        }
        if event.type == .motion && event.subtype == .motionShake {
            NotificationCenter.default.post(name: .motionShakeEnd, object: self)
        }
    }
}
 */
