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
        #if DEBUG
        // If logout at start remove token
        if Prephirences.Auth.Logout.atStart {
            _ = APIManager.instance.logout(token: Prephirences.Auth.Logout.token) { [weak self] _ in
                Prephirences.Auth.Logout.token = nil
                self?.login()
            }
            return
        }
        #endif
        autoLogin()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // add in queue to let other service reset the token if necessary? other way do it also here
        if Prephirences.Reset.appData {
            ApplicationPreferences.resetSettings()
        }
        foreground {
            if APIManager.isSignIn {
                logger.debug("Enter in foreground and already logged")
            } else {
                logger.debug("Enter in foreground and delogged")
                self.logout {
                    if let viewController = UIApplication.topViewController {
                        self.logoutUI(nil, viewController)
                    }
                }
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // if application need touch id
        //   show touch id
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // if application must disconnect when finish
        //   remove token
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        // if application could verify a token in url to verify auth
        //    do authentification with it
    }

}

// MARK: login
extension ApplicationAuthenticate {

    static var hasLogin: Bool {
        return Prephirences.Auth.Login.form
    }

   /// If there is a valid token do nothinh, otherwise call login.
   fileprivate func autoLogin() {
        if let token = APIManager.instance.authToken, token.isValidToken {
            logger.info("Application already logged with session \(token.id)")
        } else {
            login()
        }
    }

    /// Login.
    /// If application without auth do guest login,
    /// otherwise let transition to `LoginForm`
    fileprivate func login() {
        if !ApplicationAuthenticate.hasLogin {
            self.guestLogin()
        }
        // else login form must be displayed, show flow controller or main view controller
    }

    /// Login as guest (ie. without mail).
    fileprivate func guestLogin() {
        assert(!ApplicationAuthenticate.hasLogin)
        let guestLogin = ""
        let apiManager = APIManager.instance
        let url = apiManager.base.baseURL
        _ = apiManager.authentificate(login: guestLogin) { result in
            switch result {
            case .success(let authToken):
                if !authToken.isValidToken {
                    logger.info("Application has been authenticated with 4d server `\(url)` using guest mode but no token provided."
                        + " Server admin must validate the session or accept it or next action on server could not working")
                }
                _ = self.didLogin(result: result)
            case .failure(let error):
                let error: Error = error.restErrors ?? error
                logger.error("Failed to authenticate with 4d server `\(url)` using guest mode: \(error)")
                /// XXX show full screen dialog with error message ?
                /// Or keep the information in api for next failed request.
            }
        }
        logger.info("Application is trying to authenticate with 4d server `\(url)` using guest mode.")
    }

    /// Force a logout.
    fileprivate func logout(completionHandler: @escaping () -> Void) {
        _ = APIManager.instance.logout { _ in
            completionHandler()
        }
    }

    func logoutUI(_ sender: Any? = nil, _ source: UIViewController) {
        foreground {
            /// XXX check that there is no issue with that, view controller cycle for instance
            if let destination = Main.instantiate() {
                let identifier = "logout"
                // prepare destination like done with segue
                source.prepare(for: UIStoryboardSegue(identifier: identifier, source: source, destination: destination), sender: sender)
                // and present it
                source.present(destination, animated: true) {
                    logger.debug("\(destination) presented by \(source)")
                }
            }
        }
    }

    static func retryGuestLogin( _ complementionHandler: @escaping APIManager.CompletionAuthTokenHandler) {
        let api = APIManager.instance
        _ = api.logout { _ in
            _ = api.authentificate(login: "") { authResult in
                complementionHandler(authResult)
            }
        }
    }
}
/*
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}*/

// MARK: - did login

extension Result where Success == AuthToken {
    /// Returns `true` if the use is SignIn, `false` otherwise.
    public var isSignIn: Bool {
        switch self {
        case .success(let token):
            return token.isValidToken
        case .failure:
            return false
        }
    }
}

// MARK: LoginFormDelegate
extension ApplicationAuthenticate: LoginFormDelegate {

    /// What to after login.
    func didLogin(result: Result<AuthToken, APIError>) -> Bool {
        // If reload data after login
        guard result.isSignIn else {
            self.tryCount = 0
            return false
        }
        ActionManager.instance.checkSuspend() // XXX maybe instead actionmanager must listen to login/logout

        let operation: DataSync.Operation = Prephirences.Auth.reloadData ? .reload: .sync
        /// The user have custom data. What to do?
        /// full reload?
        /// reload embedded and sync?
        /// reload only table with filter?

        // SwiftMessages.loading("\(operation.description.capitalized()) data")

        // Launch a background task to reload
        _ = BackGroundDataSyncManager.instance.sync(operation: operation) { dataResult in
            // SwiftMessages.hide()

            switch dataResult {
            case .success:
                break
            case .failure(let error):
                // XXX maybe manager this error management in DataReloadManager
                let title = "Issue when reloading data"
                if !ApplicationAuthenticate.hasLogin,
                    error.mustRetry, self.tryCount < Prephirences.Auth.Login.Guest.maxRetry {
                    self.tryCount += 1
                    let apiManager = APIManager.instance
                    _ = apiManager.logout { _ in
                        _ = apiManager.authentificate(login: "") { loginResult in
                            _ = self.didLogin(result: loginResult)
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

    /// Configure login message error if any
    fileprivate func configureErrorDisplay() -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = SwiftMessages.defaultTapHandler
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
            public static let parent = Auth.instance
            /// Save or not log in information for next log in. (save email).
            public static let save: Bool = instance["save"] as? Bool ?? true
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
                public static let parent = Login.instance
                static let maxRetry = instance["maxRetry"] as? Int ?? 2
            }
        }

        /// Logoutç authentification preferences.
        public struct Logout: Prephirencable { // swiftlint:disable:this nesting
            public static let parent = Auth.instance
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

// MARK: - Prephirencable
/*
/// some test about automatic proxy creation
protocol Prephirencable {
    static var key: String {get}
    static var parent: PreferencesType {get}
}
extension Prephirencable {
    static var key: String {
        return "\(self)".lowercasingFirst+"."
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
*/
extension String {

    fileprivate var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }
}

// MARK: - Error

extension DataSyncError {

    /// Return true if the error need a retry after relogin
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

    /// The message to describe why we retry.
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

// MARK: - sync manager

/// Manager data sync action in background
class BackGroundDataSyncManager {

    static let instance = BackGroundDataSyncManager()

    // var listeners: [DataReloadListener] = []
    var cancellable = CancellableComposite()

    fileprivate func log(operation: DataSync.Operation, _ result: DataSync.SyncResult) {
        // Just log
        switch result {
        case .success:
            logger.info("data \(operation.verb)")
        case .failure(let error):
            logger.error("data \(operation.description) failed \(error)")
        }
    }

    func sync(operation: DataSync.Operation, delay: TimeInterval = 3, _ completionHandler: DataSync.SyncCompletionHandler? = nil) -> Cancellable {
        cancellable.cancel()
        cancellable = CancellableComposite()

        background(delay) { [weak self] in
            guard let this = self else {return}

            let reload = dataSync(operation: operation) { [weak self] result in
                guard let this = self else {return}

                this.log(operation: operation, result)
                // this.notify(result)
                completionHandler?(result)
            }
            if let reload = reload {
                this.cancellable.append(reload)
            }
        }
        return cancellable
    }

    func didLogout() {
        cancellable.cancel()
    }
}
