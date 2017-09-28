//
//  NumberFormatter+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension NumberFormatter {

    /// Specifies no style, such that an integer representation is used; for example, 1234.5678 is represented as “1235”.
    static let none: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    /// Specifies a decimal style format; for example, 1234.5678 is represented as “1234.5678”.
    static let decimal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Specifies a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$ 1234.57”.
    static let currency: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    /// Specifies a percent style format; for example, 1234.5678 is represented as “123457%”.
    static let percent: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    /// Specifies a spell-out format; for example, 1234.5678 is represented as “one thousand two hundred thirty-four point five six seven eight”.
    static let spellOut: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()

    /// Specifies an ordinal format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1,235th”
    static let ordinal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    /// Specifies a currency style format using ISO 4217 currency codes; for example, in the en_US_POSIX locale, 1234.5678 is represented as “USD 1234.57”.
    static let currencyISOCode: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        return formatter
    }()

    /// Specifies a currency style format, using pluralized denominations; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1234.57 US dollars”.
    static let currencyPlural: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyPlural
        return formatter
    }()

    /// Specifies a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$1234.57”.
    /// Unlike currency, negative numbers representations are surrounded by parentheses rather than preceded by a negative symbol; for example, in the en_US_POSIX locale, -1234.5678 is represented as “($1,234.57)”.
    static let currencyAccounting: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        return formatter
    }()

}
