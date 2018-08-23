//
//  UIButton+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

// Use some Formatter to bind button
public extension UIButton {

    // MARK: - string

    private var text: String? {
        get {
            return self.titleLabel?.text
        }
        set {
            self.titleLabel?.text = newValue
        }
    }

    /// Display a data with RFC 822 format
    @objc dynamic public var localized: String? {
        get {
            guard let localized = self.text else {
                return nil
            }
            return localized // Cannot undo it...
        }
        set {
            guard let string = newValue else {
                self.text = nil
                return
            }
            self.text = string.localizedBinding
        }
    }

    // MARK: - date

    /// Display a data with RFC 822 format
    @objc dynamic public var date: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.rfc822.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.rfc822.string(from: date)
        }
    }

    /// Display a data with a short style, typically numeric only, such as “11/23/37”.
    @objc dynamic public var shortDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.shortDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.shortDate.string(from: date)
        }
    }

    /// Display a data with a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    @objc dynamic public var mediumDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.mediumDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.mediumDate.string(from: date)
        }
    }

    /// Display a data with a long style, typically with full text, such as “November 23, 1937”.
    @objc dynamic public var longDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.longDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.longDate.string(from: date)
        }
    }

    /// Display a data with a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    @objc dynamic public var fullDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.fullDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.fullDate.string(from: date)
        }
    }

    // MARK: - time (duration)

    /// Display a time with a short style, typically numeric only, such as “3:30 PM”.
    @objc dynamic public var shortTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.short.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.short.string(from: number)
        }
    }

    /// Display a time with a medium style, typically with abbreviated text, such as “3:30:32 PM”.
    @objc dynamic public var mediumTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.medium.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.medium.string(from: number)
        }
    }

    /// Display a time with a long style, typically with full text, such as “3:30:32 PM PST”.
    @objc dynamic public var longTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.long.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.long.string(from: number)
        }
    }

    /// Display a time with a full style with complete details, such as “3:30:42 PM Pacific Standard Time”.
    @objc dynamic public var fullTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.full.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.full.string(from: number)
        }
    }

    // MARK: - bool

    /// Display 1 or 0 for boolean value
    @objc dynamic public var bool: Bool {
        get {
            return integer == 1
        }
        set {
            integer = newValue ? 1: 0
        }
    }

    @objc dynamic public var boolean: NSNumber? {
        get {
            return integer
        }
        set {
            integer = boolean
        }
    }

    /// Display yes or no for boolean value
    @objc dynamic public var noOrYes: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "Yes".localizedFramework
        }
        set {
            text = newValue ? "Yes".localizedFramework: "No".localizedFramework
        }
    }

    /// Display true or false for boolean value
    @objc dynamic public var falseOrTrue: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "True".localizedFramework
        }
        set {
            text = newValue ? "True".localizedFramework: "False".localizedFramework
        }
    }

    // MARK: - number

    /// Display a number with a decimal style format; for example, 1234.5678 is represented as “1234.5678”.
    @objc dynamic public var decimal: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.decimal.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.decimal.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$ 1234.57”.
    @objc dynamic public var currency: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currency.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currency.string(from: number)

        }
    }

    /// Display a number with a currency style format using ISO 4217 currency codes; for example, in the en_US_POSIX locale, 1234.5678 is represented as “USD 1234.57”.
    @objc dynamic public var currencyISOCode: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyISOCode.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyISOCode.string(from: number)

        }
    }

    /// Display a number with a percent style format; for example, 1234.5678 is represented as “123457%”.
    @objc dynamic public var percent: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.percent.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.percent.string(from: number)

        }
    }

    /// Display a number with no style, such that an integer representation is used; for example, 1234.5678 is represented as “1235”.
    @objc dynamic public var integer: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.none.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.none.string(from: number)

        }
    }

    /// Display a number with a spell-out format; for example, 1234.5678 is represented as “one thousand two hundred thirty-four point five six seven eight”.
    @objc dynamic public var spellOut: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.spellOut.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.spellOut.string(from: number)

        }
    }

    /// Display a number with an ordinal format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1,235th”
    @objc dynamic public var ordinal: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.ordinal.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.ordinal.string(from: number)

        }
    }

    // MARK: image
    @objc dynamic public var restImage: [String: Any]? {
        get {
            return self.imageView?.restImage
        }
        set {
            self.imageView?.restImage = newValue
        }
    }

    @objc dynamic public var imageNamed: String? {
        get {
            return self.imageView?.imageNamed
        }
        set {
            // XXX create imageView?
            self.imageView?.imageNamed = newValue
        }
    }
}
