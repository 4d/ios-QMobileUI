//
//  UIDevice+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

// MARK: - Current
public extension UIDevice {

    class var idForVendor: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    class var systemFloatVersion: Float {
        return (UIDevice.current.systemVersion as NSString).floatValue
    }

    class var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }

    class var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
}

// MARK: - Language
public extension UIDevice {

    class var deviceLanguage: String {
        return Bundle.main.preferredLocalizations[0]
    }

}

// MARK: - Version
public extension UIDevice {

    class func isVersion(_ version: Float) -> Bool {
        return systemFloatVersion >= version && systemFloatVersion < (version + 1.0)
    }

    class func isVersionOrLater(_ version: Float) -> Bool {
        return systemFloatVersion >= version
    }

    class func isVersionOrEarlier(_ version: Float) -> Bool {
        return systemFloatVersion < (version + 1.0)
    }

}

public extension UIDevice {

    func forceRotation(_ orientation: UIInterfaceOrientation) {
        setValue(orientation.rawValue, forKey: "orientation")
    }

    class func forceRotation(_ orientation: UIInterfaceOrientation) {
        UIDevice.current.forceRotation(orientation)
    }

}
