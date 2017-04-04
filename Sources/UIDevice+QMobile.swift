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

    public class var idForVendor: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    public class var systemFloatVersion: Float {
        return (UIDevice.current.systemVersion as NSString).floatValue
    }

    public class var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }

    public class var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
}

// MARK: - Language
public extension UIDevice {

    public class var deviceLanguage: String {
        return Bundle.main.preferredLocalizations[0]
    }

}

// MARK: - Version
public extension UIDevice {

    public class func isVersion(_ version: Float) -> Bool {
        return systemFloatVersion >= version && systemFloatVersion < (version + 1.0)
    }

    public class func isVersionOrLater(_ version: Float) -> Bool {
        return systemFloatVersion >= version
    }

    public class func isVersionOrEarlier(_ version: Float) -> Bool {
        return systemFloatVersion < (version + 1.0)
    }

}

public extension UIDevice {

    public func forceRotation(_ orientation: UIInterfaceOrientation) {
        setValue(orientation.rawValue, forKey: "orientation")
    }

    public class func forceRotation(_ orientation: UIInterfaceOrientation) {
        UIDevice.current.forceRotation(orientation)
    }

}
