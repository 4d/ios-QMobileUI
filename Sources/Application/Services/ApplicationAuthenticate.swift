//
//  ApplicationAuthentificate.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

import UIKit
import Prephirences
import QMobileAPI

/// Log the step of application launching
class ApplicationAuthenticate: NSObject {

    override init() {
    }

}

extension ApplicationAuthenticate: ApplicationService {

    static var instance: ApplicationService = ApplicationAuthenticate()

    var hasLoginForm: Bool {
        return Prephirences.sharedInstance["auth.withForm"] as? Bool ?? false
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let apiManager = APIManager.instance
        let keyChain = KeychainPreferences.sharedInstance
        if let authToken = keyChain["auth.token"] as? AuthToken {
            apiManager.authToken = authToken
        } else {
            if hasLoginForm {
                // TODO show login form
            } else {
                // login guest mode
                let guestLogin = ""
                let cancellable = apiManager.authentificate(login: guestLogin) { result in
                    switch result {
                    case .success(let authToken):
                        apiManager.authToken = authToken
                        if authToken.isValidToken {
                            apiManager.authToken = authToken
                        } else {
                            logger.info("Application has been authenticated with 4d server `\(apiManager.rest.baseURL)` using guest mode but no token provided. Server admin must validate the session")
                            // TODO show form with message about login
                        }
                    case .failure(let error):
                        let error: Error = error.restErrors ?? error
                        logger.error("Failed to authenticate with 4d server `\(apiManager.rest.baseURL)` using guest mode: \(error)")
                        // TODO show full screen dialog with error message
                    }
                }
                logger.info("Application is trying to authenticate with 4d server `\(apiManager.rest.baseURL)` using guest mode. \(cancellable)")
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // if application need touch id
        //   show touch id
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // if application must disconnect when finish
        //   remove token
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // if application could verify a token to verify auth
        //    do authentification with it
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) {
        // if application could verify a token in url to verify auth
        //    do authentification with it
    }

}
