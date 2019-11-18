//
//  ApplicationUpdate.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/12/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences
import QMobileAPI
import Moya

public class ApplicationUpdate: NSObject {

    public weak var delegate: ApplicationUpdateDelegate?

    public var updaterWindow: UIWindow?

    public var appID: Int?
    var currentAppStoreVersion: String?

    var alertViewIsVisible: Bool = false
    var updateType: UpdateType = .unknown

    public var alertType: AlertType = .option {
        didSet {
            alertTypes[.major] = alertType
            alertTypes[.minor] = alertType
            alertTypes[.patch] = alertType
            alertTypes[.revision] = alertType
        }
    }
    public var alertTypes: [UpdateType: AlertType] = [:]

}

extension ApplicationUpdate: ApplicationService {

    public static let instance: ApplicationService = ApplicationUpdate()

    public static var shared: ApplicationUpdate {
        // swiftlint:disable:next force_cast
        return instance as! ApplicationUpdate
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {

    }

    public func applicationDidEnterBackground(_ application: UIApplication) {

    }

    public func applicationDidBecomeActive(_ application: UIApplication) {

    }
}

public enum ApplicationUpdateError: Error {
    case noBundleId
    case appStoreAppIDFailure
    case appStoreDataRetrievalFailure(underlyingError: Error?)
    case appStoreOSVersionNumberFailure
    case appStoreOSVersionUnsupported
    case appStoreVersionArrayFailure
    case malformedURL
    case noUpdateAvailable
    case recentlyCheckedAlready
}

// MARK: version checking

public enum UpdateType: String {
    case major
    case minor
    case patch
    case revision
    case unknown
}

extension ApplicationUpdate {

    func setAlertType() -> AlertType {
        let currentInstalledVersion = UIApplication.appVersion
        guard let currentAppStoreVersion = currentAppStoreVersion else {
                return .option
        }

        let oldVersion = (currentInstalledVersion).split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
        let newVersion = (currentAppStoreVersion).split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}

        guard let newVersionFirst = newVersion.first, let oldVersionFirst = oldVersion.first else {
            return self.alertType // Default value is .Option
        }

        var alertType = self.alertType
        if newVersionFirst > oldVersionFirst { // A.b.c.d
            alertType = alertTypes[.major] ?? .default
            updateType = .major
        } else if newVersion.count > 1 && (oldVersion.count <= 1 || newVersion[1] > oldVersion[1]) { // a.B.c.d
            alertType = alertTypes[.minor] ?? .default
            updateType = .minor
        } else if newVersion.count > 2 && (oldVersion.count <= 2 || newVersion[2] > oldVersion[2]) { // a.b.C.d
            alertType = alertTypes[.patch] ?? .default
            updateType = .patch
        } else if newVersion.count > 3 && (oldVersion.count <= 3 || newVersion[3] > oldVersion[3]) { // a.b.c.D
            alertType = alertTypes[.revision] ?? .default
            updateType = .revision
        }

        return alertType
    }

    public func performVersionCheck() -> Cancellable? {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            postError(.noBundleId)
            return nil
        }

        if preferences["update.checkingOnAppStore"] as? Bool ?? false {
            return ItunesAPI.lookup(bundleId: bundleId) { result in
                switch result {
                case .success(let items):
                    if let item = items.results.first, item.bundleId == bundleId {
                        let info = item.applicationInfo
                        self.processVersionCheck(for: info)

                    } else {
                        self.postError(.appStoreDataRetrievalFailure(underlyingError: nil))
                    }

                case .failure(let error):
                    self.postError(.appStoreDataRetrievalFailure(underlyingError: error))
                }
            }
        } else {
            let action = preferences["update.4daction"] as? String ?? "mdm_applicationinfo"
            return APIManager.instance.loadApplicationInfo(actionName: action, bundleId: bundleId) { [unowned self] result in
                switch result {
                case .success(let info):
                    self.processVersionCheck(for: info)
                case .failure(let error):
                    self.postError(.appStoreDataRetrievalFailure(underlyingError: error))
                }
            }

        }
    }

    func processVersionCheck(for info: ApplicationInfo) {
        guard isUpdateCompatibleWithDeviceOS(for: info) else {
            return
        }

        guard let appID = info.id else {
            postError(.appStoreAppIDFailure)
            return
        }
        self.appID = appID
        guard let currentAppStoreVersion = info.version else {
            postError(.appStoreVersionArrayFailure)
            return
        }

        guard isAppVersionOlder(than: currentAppStoreVersion) else {
            delegate?.applicationUpdateLatestVersionInstalled()
            postError(.noUpdateAvailable)
            return
        }
        _ = setAlertType() // maybe rename to get update type
        showAlert()
    }

    public enum AlertType {
        /// Mandatory update, user must update
        case mandatory
        /// Optional update, user can cancel
        case option
        /// No alert, just call delegate
        case none

        /// Default alert type ie. `option`.
        public static let `default`: AlertType = .option
    }

    func showAlert(_ alertType: AlertType = .default) {

        storeVersionCheckDate()

        let updateTitle = "Update Available"

        let updateMessage = newVersionMessage()

        let alertController = UIAlertController(title: updateTitle, message: updateMessage, preferredStyle: .alert)

        switch alertType {
        case .mandatory:
            alertController.addAction(updateAlertAction())
        case .option:
            alertController.addAction(nextTimeAlertAction())
            alertController.addAction(updateAlertAction())
        case .none:
            delegate?.applicationUpdateDidDetectNewVersionWithoutAlert(message: updateMessage, updateType: updateType)
        }

        if alertType != .none && !alertViewIsVisible {
            alertController.show()
            alertViewIsVisible = true
            delegate?.applicationUpdateDidShowUpdateDialog(alertType: alertType)
        }
    }

    func newVersionMessage() -> String {
        let newVersionMessage = "A new version of %@ is available. Please update to version %@ now."
        guard let currentAppStoreVersion = currentAppStoreVersion else {
            return String(format: newVersionMessage, UIApplication.appName, "Unknown")
        }
        return String(format: newVersionMessage, UIApplication.appName, currentAppStoreVersion)
    }

    func hideWindow() {
        if let updaterWindow = updaterWindow {
            updaterWindow.isHidden = true
            self.updaterWindow = nil
        }
    }

    func updateAlertAction() -> UIAlertAction {
        let title = "Update"
        let action = UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.hideWindow()
            self.openUpdate()
            self.alertViewIsVisible = false
            return
        }

        return action
    }

    func nextTimeAlertAction() -> UIAlertAction {
        let title = "Next time"
        let action = UIAlertAction(title: title, style: .default) { [unowned self] _  in
            self.hideWindow()
            self.delegate?.applicationUpdateUserDidCancel()
            self.alertViewIsVisible = false
            return
        }

        return action
    }

    func isAppVersionOlder(than version: String) -> Bool {
         return UIApplication.appVersion.compare(version, options: .numeric) == .orderedAscending
    }

    func isUpdateCompatibleWithDeviceOS(for info: ApplicationInfo) -> Bool {
        guard let requiredOSVersion = info.minimumOsVersion else {
            postError(.appStoreOSVersionNumberFailure)
            return false
        }

        let systemVersion = UIDevice.current.systemVersion

        guard systemVersion.compare(requiredOSVersion, options: .numeric) == .orderedDescending ||
            systemVersion.compare(requiredOSVersion, options: .numeric) == .orderedSame else {
                postError(.appStoreOSVersionUnsupported)
                return false
        }

        return true
    }

    fileprivate func storeVersionCheckDate() {
        lastVersionCheckDate = Date()
        UserDefaults.standard.synchronize()
    }

    public var lastVersionCheckDate: Date? {
        get {
            return preferences["appUpdateLastVersionCheck"] as? Date
        }
        set {
            var preferences = self.preferences
            preferences["appUpdateLastVersionCheck"] = newValue
        }
    }

    public var updateURL: URL? {
        guard let appID = preferences["appStoreID"] as? String else {
            return nil
        }
        return URL(string: "https://itunes.apple.com/app/id\(appID)")
    }

    /// Action when asking update
    public func openUpdate() {
        if preferences["update.openUI"] as? Bool ?? true {
            openUpdateUI()
        } else {
            openUpdateURL()
        }
    }
    public func openUpdateUI() {
        self.delegate?.applicationUpdateUserDidOpenUpdateUI()
        openUpdateURL() // TODO APP UPDATE implement a real UI, segue?
    }

    public func openUpdateURL() {
        if let url = updateURL {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { res in
                    logger.debug("Update url '\(url)' opened result: \(res) ")
                }
            }
            self.delegate?.applicationUpdateUserDidOpenUpdateURL()
        } else {
            logger.warning("No update url defined for application")
            assertionFailure("No update url defined for application")
        }
    }

    func postError(_ error: ApplicationUpdateError) {
        delegate?.applicationUpdateDidFailVersionCheck(error: error)
        logger.warning(error.localizedDescription)
    }
}

// MARK: delegate

/// Delegate for application update checking process.
public protocol ApplicationUpdateDelegate: NSObjectProtocol {
    /// User presented with update dialog.
    func applicationUpdateDidShowUpdateDialog(alertType: ApplicationUpdate.AlertType)

    /// User did click on button that open the update UI.
    func applicationUpdateUserDidOpenUpdateUI()

    /// User did click on button that open the update URL (Which could open the app store).
    func applicationUpdateUserDidOpenUpdateURL()

    /// User did click on button that cancels update dialog.
    func applicationUpdateUserDidCancel()

    /// applicationUpdate failed to perform version check.
    func applicationUpdateDidFailVersionCheck(error: Error)

    /// applicationUpdate performed version check and did not display alert.
    func applicationUpdateDidDetectNewVersionWithoutAlert(message: String, updateType: UpdateType)

    /// applicationUpdate performed version check and latest version is already installed.
    func applicationUpdateLatestVersionInstalled()
}

// MARK: Alert controller

extension UIAlertController {
    func showUpdate() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = AppUpdateViewController() // keep style
        window.windowLevel = UIWindow.Level.alert + 1 // on top

       ApplicationUpdate.shared.updaterWindow = window

        window.makeKeyAndVisible()
        window.rootViewController!.present(self, animated: true, completion: nil)
    }
}

final class AppUpdateViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return UIApplication.shared.statusBarStyle }
}
