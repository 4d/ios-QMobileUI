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
import Result
import Moya
import SwiftMessages

import QMobileAPI
import QMobileDataSync

/// Log the step of application launching
class ApplicationAuthenticate: NSObject {

    private var observers: [NSObjectProtocol] = []
    private var tryCount: Int = 0
    override init() {
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
        if Prephirences.Auth.Login.Guest.enabled {
            self.guestLogin()
        }
        // else login form must be displayed, show flow controller or main view controller
    }

    func guestLogin() {
        assert(Prephirences.Auth.Login.Guest.enabled)
        let apiManager = APIManager.instance
        // login guest mode
        let guestLogin = ""
        _ = apiManager.authentificate(login: guestLogin) { result in
            switch result {
            case .success(let authToken):
                if !authToken.isValidToken {
                    logger.info("Application has been authenticated with 4d server `\(apiManager.base.baseURL)` using guest mode but no token provided."
                        + " Server admin must validate the session or accept it or next action on server could not working")
                }
                _ = self.didLogin(result: result)
            case .failure(let error):
                let error: Error = error.restErrors ?? error
                logger.error("Failed to authenticate with 4d server `\(apiManager.base.baseURL)` using guest mode: \(error)")
                /// XXX show full screen dialog with error message ?
                /// Or keep the information in api for next failed request.
            }
        }
        logger.info("Application is trying to authenticate with 4d server `\(apiManager.base.baseURL)` using guest mode.")
    }

    func logout(completionHandler: @escaping () -> Void) {
        _ = APIManager.instance.logout { _ in
            completionHandler()
        }
    }

}

// MARK: LoginFormDelegate
extension ApplicationAuthenticate: LoginFormDelegate {

    /// When login manage what to do.
    func didLogin(result: Result<AuthToken, APIError>) -> Bool {
        // If reload data after login
        guard result.isSuccess else { return false }
        // If reload data after login
        guard Prephirences.Auth.reloadData else { return false }

        SwiftMessages.loading("Reloading data")
        // Launch a background task to reload
        _ = DataReloadManager.instance.reload { result in
            SwiftMessages.hide()

            switch result {
            case .success:
                break
            case .failure(let error):

                // XXX maybe manager this error management in DataReloadManager
                let title = "Issue when reloading data"
                if Prephirences.Auth.Login.Guest.enabled,
                    error.mustRetry, self.tryCount < Prephirences.Auth.Login.Guest.maxRetry {
                    self.tryCount += 1
                    let api = APIManager.instance
                    _ = api.logout { _ in
                        _ = APIManager.instance.authentificate(login: "") { result in
                            _ = self.didLogin(result: result)
                        }
                    }
                } else {
                    SwiftMessages.error(title: error.errorDescription ?? title,
                                        message: error.failureReason ?? "",
                                        configure: self.configureErrorDisplay())
                }
            }
        }
        return true
    }

    fileprivate func configureErrorDisplay() -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = { _ in
                SwiftMessages.hide()
            }
            var config = config
            config.presentationStyle = .center
            config.duration = .forever
            // no interactive because there is no way yet to get background tap handler to make logout
            config.dimMode = .gray(interactive: false)
            return config
        }
    }

}

// MARK: Preferences

extension Prephirences {

    /// Authentification preferences.
    public struct Auth: Prephirencable {
        /// Application will reload data after logIn.
        public static let reloadData: Bool = instance["reloadData"] as? Bool ?? false

        /// Login authentification preferences.
        public struct Login: Prephirencable { // swiftlint:disable:this nesting
            static let parent = Auth.instance
            /// Save or not log in information for next log in. (save email).
            public static let save: Bool = instance["save"] as? Bool ?? false
            /// Email saved to log
            public static var email: String? {
                get {
                    return instance["email"] as? String
                }
                set {
                    mutableInstance?.set(newValue, forKey: "email")
                }
            }
            /// Application will start with login form.
            public static let form: Bool = instance["form"] as? Bool ?? false

            /// Guest mode login authentification preferences.
            public struct Guest: Prephirencable { // swiftlint:disable:this nesting
                static let parent = Login.instance
                static let maxRetry = instance["maxRetry"] as? Int ?? 2

                // Guest mode is enabled if there is no login form
                static let enabled: Bool = !Prephirences.Auth.Login.form
            }
        }

        /// Logoutç authentification preferences.
        public struct Logout: Prephirencable { // swiftlint:disable:this nesting
            static let parent = Auth.instance
            /// Application will ask for login screen each time, event if alread logged before. (Default false)
            public static let atStart: Bool = instance["atStart"] as? Bool ?? false
            /// token saved temporary to logout
            public static var token: String? {
                get {
                    return instance["token"] as? String
                }
                set {
                    mutableInstance?.set(newValue, forKey: "token")
                }
            }
        }
    }

}

/// some test about automatic proxy creation
protocol Prephirencable {
    static var key: String {get}
    static var parent: PreferencesType {get}
}
extension Prephirencable {
    static var key: String {
        return "\(self)".lowercased()+"."
    }
    static var parent: PreferencesType {
        return Prephirences.sharedInstance
    }
    static var instance: PreferencesType {
        return ProxyPreferences(preferences: parent, key: key)
    }
    static var mutableInstance: MutablePreferencesType? {
        guard let parent = parent as? MutablePreferencesType else {
            return nil
        }
        return MutableProxyPreferences(preferences: parent, key: key)
    }
}

// MARK: Error
extension DataSyncError {

    var mustRetry: Bool {
        if case .apiError(let apiError) = self {
            if apiError.isHTTPResponseWith(code: .unauthorized) {
                return true
            }
            if let restErrors = apiError.restErrors, restErrors.match(.query_placeholder_is_missing_or_null) {
                return true
            }
        }
        return false
    }

    var mustRetryMessage: String {
        if case .apiError(let apiError) = self {
            if apiError.isHTTPResponseWith(code: .unauthorized) {
                return "You have been disconnected"
            }
            if let restErrors = apiError.restErrors, restErrors.match(.query_placeholder_is_missing_or_null) {
                return "You need to reconnect to reload."
            }
        }
        return ""
    }
}

// MARK: reload manager

/// Manager data reload action
class DataReloadManager {

    static let instance = DataReloadManager()

    //var listeners: [DataReloadListener] = []
    var cancellable = CancellableComposite()

    fileprivate func log(_ result: DataSync.SyncResult) {
        // Just log
        switch result {
        case .success:
            logger.info("data reloaded")
        case .failure(let error):
            logger.error("data reloading failed \(error)")
        }
    }

    func reload(delay: TimeInterval = 3, _ completionHandler: DataSync.SyncCompletionHandler? = nil) -> Cancellable {
        cancellable.cancel()
        cancellable = CancellableComposite()

        let center = NotificationCenter.default
        background(delay) { [weak self] in
            guard let this = self else {return}

            //center.addObserver(this, selector: #selector(this.application(didEnterBackground:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

            let reload = dataReload { [weak self] result in
                guard let this = self else {return}

                center.removeObserver(this)

                this.log(result)
                //this.notify(result)
                completionHandler?(result)
            }
            if let reload = reload {
                this.cancellable.append(reload)
            }
        }
        return cancellable
    }
}
