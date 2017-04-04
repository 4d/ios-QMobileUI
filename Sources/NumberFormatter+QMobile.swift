//
//  NumberFormatter+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension NumberFormatter {

    static let none: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    static let decimal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static let currency: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    static let percent: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    static let spellOut: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()

    static let ordinal: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    static let currencyISOCode: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        return formatter
    }()

    static let currencyPlural: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyPlural
        return formatter
    }()

    static let currencyAccounting: NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        return formatter
    }()

}
