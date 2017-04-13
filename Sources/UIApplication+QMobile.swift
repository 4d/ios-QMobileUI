//
//  UIApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

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

extension UIApplicationDelegate {

    public static var shared: UIApplicationDelegate {
        //swiftlint:disable:next force_cast
        return UIApplication.shared.delegate!
    }

}
