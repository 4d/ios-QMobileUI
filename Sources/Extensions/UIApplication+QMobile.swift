//
//  UIApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences
import UIKit

// MARK: App informations
extension UIApplication {

    public static var appName: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleDisplayName] as! String
    }
    public static var appVersion: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleShortVersionString] as! String
    }
    public static var build: String {
        // swiftlint:disable:next force_cast
        return Bundle.main[.CFBundleVersion] as! String
    }
    public static var versionBuild: String {
        let version = self.appVersion
        let build = self.build
        if version != build {
            return "v\(version) (\(build)%@)"
        }
        return "v\(version)"
    }

    /// Check if app is running in debugging mode, ie. compilator flag DEBUG is set.
    public static var isInDebuggingMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Check if app is running in TestFlight mode.
    public static var isInTestFlight: Bool {
        // http://stackoverflow.com/questions/12431994/detect-testflight
        return Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") == true
    }
}

// MARK: Shared application shortcut
extension UIApplicationDelegate {

    public static var shared: UIApplicationDelegate {
        // swiftlint:disable:next force_cast
        return UIApplication.shared.delegate!
    }

}

extension UIApplication {

    static func redirectToAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    open class var isLandscapeOrientation: Bool {
        return UIApplication.shared.topWindowScene?.interfaceOrientation.isLandscape ?? false
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

extension UIInterfaceOrientation {

    var isLandscape: Bool {
        switch self {
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
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
    /// Do not call in app extension, UIApplication.shared not exist
    public static var topViewController: UIViewController? {
        return UIApplication.shared.topViewController
    }

    @available(iOS 13.0, *)
    public var connectedWindowScenes: [UIWindowScene] {
        return self.connectedScenes.compactMap { $0 as? UIWindowScene }
    }

    @available(iOS 13.0, *)
    public var topWindowScene: UIWindowScene? {
        let scenes = connectedWindowScenes
        return scenes.filter { $0.activationState == .foregroundActive }.first ?? scenes.first
    }

    public var topWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return self.topWindowScene?.windows.first
        } else {
            return self.keyWindow
        }
    }

    public var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return self.topWindowScene?.statusBarManager?.statusBarFrame.size.height ?? 0
        } else {
            return statusBarFrame.size.height
        }
    }

    public var topViewController: UIViewController? {
        guard let rootController = self.topWindow?.rootViewController else {
            return nil
        }
        return UIViewController.topViewController(rootController)
    }

    /// Return the top navigation controller.
    static var topNavigationController: UINavigationController? {
        guard let topViewController = UIApplication.shared.topViewController else {
            return nil
        }
        if let navigationController = topViewController as? UINavigationController {
            return navigationController
        }
        return topViewController.navigationController
    }
}
