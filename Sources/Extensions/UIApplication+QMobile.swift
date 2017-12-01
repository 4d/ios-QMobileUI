//
//  UIApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

// MARK: App informations
extension UIApplication {

    open static var appName: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleDisplayName] as! String
    }
    open static var appVersion: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleShortVersionString] as! String
    }
    open static var build: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleVersion] as! String
    }
    open static var versionBuild: String {
        let version = self.appVersion
        let build = self.build
        if version != build {
            return "v\(version) (\(build)%@)"
        }
        return "v\(version)"
    }

}

// MARK: Shared application shortcut
extension UIApplicationDelegate {

    public static var shared: UIApplicationDelegate {
        //swiftlint:disable:next force_cast
        return UIApplication.shared.delegate!
    }

}

extension UIApplication {

    static func redirectToAppSettings() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    open class var isLandscapeOrientation: Bool {
        return UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
    }

    open class var isUserRegisteredForRemoteNotifications: Bool {
        if #available(iOS 8.0, *) {
            return UIApplication.shared.isRegisteredForRemoteNotifications
        } else {
            // Fallback on earlier versions
            return true
        }
    }

}

// MARK: responder

extension UIApplication {

    // dismiss Keyboard
    @objc class func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private struct CurrentResponder {
        static weak var currentResponder: UIResponder?
    }

    class func currentFirstResponder() -> UIResponder? {
        CurrentResponder.currentResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return CurrentResponder.currentResponder
    }

    @objc func findFirstResponder(_ sender: AnyObject?) {
        CurrentResponder.currentResponder = self
    }
}

// MARK: Controller
extension UIApplication {
    // Do not call in app extension, UIApplication.shared not exist
    open static var topViewController: UIViewController? {
            return UIApplication.shared.topViewController
    }

    open var topViewController: UIViewController? {
        guard let rootController = self.keyWindow?.rootViewController else {
            return nil
        }
        return UIViewController.topViewController(rootController)
    }
}
