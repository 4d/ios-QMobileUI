//
//  NSRegularExpression+QMobile.swift
//  QMobileUI
//
//  Created by phimage on 29/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation

// MARK: Regex

extension NSRegularExpression {
    static let email = try! NSRegularExpression(pattern: "^"+String.emailRegex, options: []) // swiftlint:disable:this force_try
    static let nonAlphanumeric = try! NSRegularExpression(pattern: String.nonAlphanumericRegex) // swiftlint:disable:this force_try
    static let firstCharacter = try! NSRegularExpression(pattern: String.firstCharacterRegex) // swiftlint:disable:this force_try
}
extension NSPredicate {
    static let email = NSPredicate(format: "SELF MATCHES %@", String.emailRegex)
}

extension String {

    static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    static let nonAlphanumericRegex = "[^a-zA-Z\\d]"
    static let firstCharacterRegex = "(\\b\\w|(?<=_)[^_])"

    public var isValidEmail: Bool {
        return NSPredicate.email.evaluate(with: self)
    }

}

extension NSRegularExpression {

    func matched(_ string: String) -> (String, CountableRange<Int>)? {
        let range = self.rangeOfFirstMatch(in: string, options: [], range: NSRange(0 ..< string.utf16.count))
        if range.location != NSNotFound {
            return ((string as NSString).substring(with: range), range.location ..< range.location + range.length)
        }
        return nil
    }
}
