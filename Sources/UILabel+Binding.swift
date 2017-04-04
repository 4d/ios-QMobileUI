//
//  UILabel+Binding.swift
//  Invoices
//
//  Created by Eric Marchand on 31/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

// Use some Formatter to bind label
public extension UILabel {

    // MARK: date
    dynamic public var date: Date? {
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
    
    dynamic public var shortDate: Date? {
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
    
    dynamic public var mediumDate: Date? {
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
    
    dynamic public var longDate: Date? {
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

    // MARK: bool

    dynamic public var bool: Bool {
        get {
            return integer == 1
        }
        set {
            integer = newValue ? 1: 0
        }
    }

    dynamic public var yesOrNo: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "Yes".localized
        }
        set {
            text = newValue ? "Yes".localized: "No".localized
        }
    }

    // MARK: number
    dynamic public var decimal: NSNumber? {
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

    dynamic public var currency: NSNumber? {
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

    dynamic public var percent: NSNumber? {
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

    dynamic public var integer: NSNumber? {
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

    dynamic public var spellOut: NSNumber? {
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

    dynamic public var ordinal: NSNumber? {
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

}
