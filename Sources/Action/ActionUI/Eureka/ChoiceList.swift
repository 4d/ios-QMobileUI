//
//  ChoiceList.swift
//  QMobileUI
//
//  Created by Eric Marchand on 25/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

/// Represent a choice in choice list
struct ChoiceList {

    /// the choice list
    var options: [ChoiceListItem]

    /// Create a choice list frm decoded data and parameter type.
    init?(choiceList: AnyCodable, type: ActionParameterType) {
        if let choiceArray = choiceList.value as? [Any] {
            options = choiceArray.enumerated().map { (arg) -> ChoiceListItem in
                let (key, value) = arg
                switch type {
                case .bool, .boolean:
                    return ChoiceListItem(key: key == 1, value: value)
                case .string:
                    return ChoiceListItem(key: "\(key)", value: value)
                case .number:
                    return ChoiceListItem(key: Double(key), value: value)
                default:
                    return ChoiceListItem(key: key, value: value)
                }
            }
        } else if let choiceDictionary = choiceList.value as? [AnyHashable: Any] {
            options = choiceDictionary.map { (arg) -> ChoiceListItem in
                let (key, value) = arg

                if let string = key as? String {
                    switch type {
                    case .bool, .boolean:
                        return ChoiceListItem(key: string.boolValue || string == "true", value: value) // "1" or "0"
                    case .integer:
                        return ChoiceListItem(key: Int(string) as Any, value: value)
                    case .number:
                        return ChoiceListItem(key: Double(string) as Any, value: value)
                    default:
                        return ChoiceListItem(key: key, value: value)
                    }
                } else {
                    // must not occurs but in case...
                    assertionFailure("key for action parameter choice is not a string \(key)")
                    return ChoiceListItem(key: key, value: value)
                }
            }
        } else {
            options = []
            return nil
        }
    }

    /// Get choice list item by key.
    func choice(for key: AnyCodable) -> ChoiceListItem? {
        for option in options where option.key == key {
            return option
        }
        if logger.isEnabledFor(level: .debug) {
            logger.debug("Default value \(key) not found in \(options.map { $0.key }) for action parameters")
            logger.verbose("Default value type \(type(of: key.value))")
            logger.verbose("Options types \(options.map { type(of: $0.key) })")
        }
        return nil
    }

}
