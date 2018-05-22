//
//  UIColor+Result.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIColor {

    /// A basic green color for success
    public static let statusSuccess: UIColor = UIColor(named: "statusSuccess") ?? UIColor(red: 129/255, green: 209/255, blue: 52/255, alpha: 1)
    /// A basic red color for failure
    public static let statusFailure: UIColor = UIColor(named: "statusFailure") ?? UIColor(red: 244/255, green: 101/255, blue: 96/255, alpha: 1)

    public var hexString: String {
        // swiftlint:disable identifier_name
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        // swiftlint:enable identifier_name

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

        return String(format: "#%06x", rgb)
    }
}
