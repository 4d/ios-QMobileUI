//
//  ApplicationLaunchOptions.swift
//  QMobileUI
//
//  Created by Eric Marchand on 27/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

public class ApplicationLaunchOptions {

    public static let instance = ApplicationLaunchOptions()

    public var apns: [AnyHashable: Any]?
    public var sourceApplication: String?
    public var url: URL?
    public var shortcut: [String: NSSecureCoding]?
    public var userActivity: NSUserActivity?

}

extension ApplicationLaunchOptions: ApplicationService {

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        url = launchOptions?[.url] as? URL
        sourceApplication = launchOptions?[.sourceApplication] as? String
        apns = launchOptions?[.remoteNotification] as? [AnyHashable: Any]
        shortcut = (launchOptions?[.shortcutItem] as? UIApplicationShortcutItem)?.userInfo
        userActivity = launchOptions?[.userActivityType] as? NSUserActivity
    }

    public func application(application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: ([Any]?) -> Void) -> Bool {

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                logger.error("The userActivity does not contain a valid passwordless URL")
                return false
        }

        guard let bundlerIdentifier = Bundle.main.bundleIdentifier, components.path.lowercased().contains(bundlerIdentifier.lowercased()),
            let items = components.queryItems else {
            logger.error("Passwordless URL does not match our bundle identifier")
            return false
        }

        guard let key = items.filter({ $0.name == "code" }).first, let passcode = key.value, Int(passcode) != nil else {
            logger.error("No valid passcode was found in the URL")
            // self.messagePresenter?.showError(PasswordlessAuthenticatableError.invalidLink)
            //se lf.dispatcher?.dispatch(result: .error(PasswordlessAuthenticatableError.invalidLink))
            return false
        }

       /* guard let passwordlessAuth = self.current else {
            logger.error("No passworldess authenticator is currently stored")
            return true
        }

        passwordlessAuth.auth(withPasscode: passcode) {
            if let error = $0 {
                Queue.main.async {
                    self.messagePresenter?.showError(error)
                }
            }
        }*/

        return true
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {

    }

}
