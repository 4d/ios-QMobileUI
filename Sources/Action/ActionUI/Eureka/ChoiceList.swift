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

/// Represent a choice in choice list
struct ChoiceListItem: Equatable {
    /// the database value, key to identify the choice
    var key: AnyCodable
    /// the value displayed to user, not real data value
    var value: AnyCodable

    init(key: Any, value: Any) {
        // unwrap any hashable or codable
        switch key {
        case let key as AnyHashable:
            self.key = AnyCodable(key.base)
        case let key as AnyCodable:
            self.key = key
        case let key as Optional<Any>:
            switch key {
            case .none:
                self.key = AnyCodable(nil)
            case .some(let key):
                self.key = AnyCodable(key)
            }
        default:
            self.key = AnyCodable(key)
        }
        switch value {
        case let value as AnyHashable:
            self.value = AnyCodable(value.base)
        case let value as AnyCodable:
            self.value = value
        default:
            self.value = AnyCodable(value)
        }
    }

    static func == (left: ChoiceListItem, right: ChoiceListItem) -> Bool {
        return left.key == right.key // && left.value == right.value, only on key
    }
}

extension ChoiceListItem: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }
}

extension ChoiceListItem: CustomStringConvertible {

    var description: String {
        return "\(value)"
    }
}
