//
//  NumberFormatter+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

extension NumberFormatter {

    /// Specifies no style, such that an integer representation is used; for example, 1234.5678 is represented as “1235”.
    static let none: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies a decimal style format; for example, 1234.5678 is represented as “1234.5678”.
    static let decimal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies a percent style format; for example, 1234.5678 is represented as “123457%”.
    static let percent: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies a spell-out format; for example, 1234.5678 is represented as “one thousand two hundred thirty-four point five six seven eight”.
    static let spellOut: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies an ordinal format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1,235th”
    static let ordinal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        configureLocal(formatter)
        return formatter
    }()

    static func configureLocal(_ formatter: NumberFormatter) {
        if let locale = preferredLocale {
            formatter.locale = locale
        } // else we use currentLocal
    }

    static var preferredLocale: Locale?  = {
        if let identifier = Prephirences.sharedInstance.string(forKey: "number.locale") ??
            Prephirences.sharedInstance.string(forKey: kFormatterLocal) {
            if identifier == kFormatterLocalPreferred, let identifier = Locale.preferredLanguages.first {
                // iOS 10 behaviour: try to use user language when formatting number
                return Locale(identifier: identifier)
            } else {
                return Locale(identifier: identifier)
            }
        }
        return nil
    }()

    // MARK: currency
    /// Specifies a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$ 1234.57”.
   /* static let currency: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        configureCurrencyLocal(formatter: formatter)
        return formatter
    }()

    /// Specifies a currency style format using ISO 4217 currency codes; for example, in the en_US_POSIX locale, 1234.5678 is represented as “USD 1234.57”.
    static let currencyISOCode: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        configureCurrencyLocal(formatter: formatter)
        return formatter
    }()

    /// Specifies a currency style format, using pluralized denominations; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1234.57 US dollars”.
    static let currencyPlural: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyPlural
        configureCurrencyLocal(formatter: formatter)
        return formatter
    }()

    /// Specifies a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$1234.57”.
    /// Unlike currency, negative numbers representations are surrounded by parentheses rather than preceded by a negative symbol; for example, in the en_US_POSIX locale, -1234.5678 is represented as “($1,234.57)”.
    static let currencyAccounting: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        configureCurrencyLocal(formatter: formatter)
        return formatter
    }()

    static func configureCurrencyLocal(formatter: NumberFormatter) {
        if let identifier = Prephirences.sharedInstance.string(forKey: "currency.local") {
            formatter.locale = Locale(identifier: identifier)
        }
    }*/

    static let currencyDollar: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .us
        return formatter
    }()

    static let currencyEuro: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .fr
        return formatter
    }()

    static let currencyYen: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .jp
        return formatter
    }()

    static let currencyLivreSterling: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .gb
        return formatter
    }()
}

extension Locale {
    //swiftlint:disable:next identifier_name
    static let us = Locale(identifier: "en_US")
    //swiftlint:disable:next identifier_name
    static let jp = Locale(identifier: "ja_JP")
    //swiftlint:disable:next identifier_name
    static let fr = Locale(identifier: "fr_FR")
    //swiftlint:disable:next identifier_name
    static let gb = Locale(identifier: "en_GB")
}
