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

    @objc dynamic var localizedText: String? {
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

    /// Display a date with RFC 822 format
    @objc dynamic var date: Date? {
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

    /// Display a date with a short style, typically numeric only, such as “11/23/37”.
    @objc dynamic var shortDate: Date? {
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

    /// Display a date with a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    @objc dynamic var mediumDate: Date? {
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

    /// Display a date with a long style, typically with full text, such as “November 23, 1937”.
    @objc dynamic var longDate: Date? {
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

    /// Display a date with a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    @objc dynamic var fullDate: Date? {
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

    /// Display a time with a short style, typically numeric only, such as “3:30”.
    @objc dynamic var duration: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.simple.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.simple.string(from: number)
        }
    }

    /// Display a time with a short style, typically numeric only, such as “3:30 PM”.
    @objc dynamic var shortTime: NSNumber? {
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
    @objc dynamic var mediumTime: NSNumber? {
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
    @objc dynamic var longTime: NSNumber? {
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
    @objc dynamic var fullTime: NSNumber? {
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
    @available(iOS, deprecated: 1.0)
    @objc dynamic var bool: Bool {
        get {
            return integer == 1
        }
        set {
            integer = newValue ? 1: 0
        }
    }

    @available(iOS, deprecated: 1.0)
    @objc dynamic var boolean: NSNumber? {
        get {
            return integer
        }
        set {
            integer = newValue
        }
    }

    /// Display yes or no for boolean value
    @objc dynamic var noOrYes: Bool {
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
    @objc dynamic var falseOrTrue: Bool {
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

    /// Display a number with no style, such that an integer representation is used; for example, 105.12345679111 is represented as “105.12345679”.
    @objc dynamic var real: NSNumber? {
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
            self.text = number.description
        }
    }

    /// Display a number with a decimal style format; for example, 1234.5678 is represented as “1234.5678”.
    @objc dynamic var decimal: NSNumber? {
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

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “$ 1234.57”.
    @objc dynamic var currencyDollar: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyDollar.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyDollar.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example,  1234.5678 is represented as “1234,57 €”.
    @objc dynamic var currencyEuro: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyEuro.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyEuro.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “£ 1234.57”.
    @objc dynamic var currencyLivreSterling: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyLivreSterling.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyLivreSterling.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “¥ 1234”.
    @objc dynamic var currencyYen: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyYen.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyYen.string(from: number)

        }
    }

    /// Display a number with a percent style format; for example, 1234.5678 is represented as “123457%”.
    @objc dynamic var percent: NSNumber? {
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
    @objc dynamic var integer: NSNumber? {
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
    @objc dynamic var spellOut: NSNumber? {
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
    @objc dynamic var ordinal: NSNumber? {
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
    @objc dynamic var restImage: [String: Any]? {
        get {
            return self.imageView?.restImage
        }
        set {
            self.imageView?.restImage = newValue
        }
    }

    @objc dynamic var imageNamed: String? {
        get {
            return self.imageView?.imageNamed
        }
        set {
            // XXX create imageView?
            self.imageView?.imageNamed = newValue
        }
    }

    @objc dynamic var systemImageNamed: String? {
        get {
            return self.imageView?.systemImageNamed
        }
        set {
            // XXX create imageView?
            self.imageView?.systemImageNamed = newValue
        }
    }
}
