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
import QMobileDataSync

/// Log the step of application launching
class ApplicationAuthenticate: NSObject {

    private var observers: [NSObjectProtocol] = []
    override init() {
    }

}

extension Prephirences {

    static func sharedProxy(_ key: String) -> PreferencesType {
        return ProxyPreferences(preferences: sharedInstance, key: key)
    }

    public struct Auth {
        private static var instance = sharedProxy("auth.")
        public static var withForm: Bool {
            return instance["withForm"] as? Bool ?? false
        }
        public static var reloadData: Bool {
            return instance["reloadData"] as? Bool ?? false
        }
        public static var mustLog: Bool {
            return instance["mustLog"] as? Bool ?? false
        }
    }

}

extension ApplicationAuthenticate: ApplicationService {

    // MARK: ApplicationService
    static var instance: ApplicationService = ApplicationAuthenticate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let apiManager = APIManager.instance
        if let authToken = apiManager.authToken, authToken.isValidToken {
            logger.info("Application already logged with session \(authToken.id)")
        } else {
            login()
        }

        /*let center = NotificationCenter.default
        let observer = center.addObserver(forName: .dataSyncFailed, object: nil, queue: .main) { [weak self] notification in
            if let syncError = notification.error as? DataSyncError, let error = syncError.error as? APIError,
                let restErrors = error.restErrors, restErrors.match(.query_placeholder_is_missing_or_null) {
                // authentificaton information are invalid, logout
                self?.logout {
                    self?.login()
                }
            }
        }
        observers.append(observer)*/
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

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        // if application could verify a token in url to verify auth
        //    do authentification with it
    }

}

// MARK: login
extension ApplicationAuthenticate {

    func login() {
        if !Prephirences.Auth.withForm {
            self.guestLogin()
        }
        // else login form must be displayed, show flow controller or main view controller
    }

    func guestLogin() {
        assert(!Prephirences.Auth.withForm)
        let apiManager = APIManager.instance
        // login guest mode
        let guestLogin = ""
        let cancellable = apiManager.authentificate(login: guestLogin) { result in
            switch result {
            case .success(let authToken):
                if !authToken.isValidToken {
                    logger.info("Application has been authenticated with 4d server `\(apiManager.base.baseURL)` using guest mode but no token provided."
                        + " Server admin must validate the session or accept it or next action on server could not working")
                }
            case .failure(let error):
                let error: Error = error.restErrors ?? error
                logger.error("Failed to authenticate with 4d server `\(apiManager.base.baseURL)` using guest mode: \(error)")
                /// XXX show full screen dialog with error message ?
                /// Or keep the information in api for next failed request.
            }
        }
        logger.info("Application is trying to authenticate with 4d server `\(apiManager.base.baseURL)` using guest mode. \(cancellable)")
    }

    func logout(completionHandler: @escaping () -> Void) {
        _ = APIManager.instance.logout { _ in
            completionHandler()
        }
    }

}
