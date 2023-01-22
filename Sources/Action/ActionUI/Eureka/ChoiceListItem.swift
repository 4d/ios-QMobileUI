//
//  ChoiceListItem.swift
//  QMobileUI
//
//  Created by Eric Marchand on 27/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import struct QMobileAPI.AnyCodable
import protocol QMobileAPI.ActionParameterEncodable
import enum QMobileAPI.ActionParameterType

/// Represent a choice in choice list
struct ChoiceListItem: Equatable, Hashable {
    /// the database value, key to identify the choice
    var key: AnyCodable
    /// the value displayed to user, not real data value
    var value: AnyCodable

    /// Initialize a choice if real value `key` and displayed `value`
    init(key: Any, value: Any) {
        // unwrap any hashable or codable
        switch key {
        case let key as AnyWrapped:
            self.key = key.codable
        default:
            self.key = AnyCodable(key)
        }
        switch value {
        case let value as AnyWrapped:
            self.value = value.codable
        default:
            self.value = AnyCodable(value)
        }
    }

    init(index: Int, value: Any, type: ActionParameterType) {
        if let entry = value as? [String: Any], let key = entry["key"], let value = entry["value"] {
            self.init(key: key, value: value, type: type)
        } else {
            // positioned collection
            switch type {
            case .bool, .boolean:
                self.init(key: index == 1, value: value)
            case .string:
                self.init(key: "\(index)", value: value)
            case .number:
                self.init(key: Double(index), value: value)
            default:
                self.init(key: index, value: value)
            }
        }
    }

    init(key: Any, value: Any, type: ActionParameterType) {
        if let string = key as? String {
            switch type {
            case .bool, .boolean:
                self.init(key: string.boolValue /* "1" or "0" */ || string == "true", value: value)
            case .integer:
                self.init(key: Int(string) as Any, value: value)
            case .number, .real:
                self.init(key: Double(string) as Any, value: value)
            default:
                self.init(key: key, value: value)
            }
        } else if let number = key as? NSNumber {
            switch type {
            case .bool, .boolean:
                self.init(key: number.boolValue, value: value)
            case .integer, .number, .real:
                self.init(key: number, value: value)
            case .string, .text:
                self.init(key: "\(number)", value: value)
            default:
                self.init(key: key, value: value)
            }
        } else if let date = key as? Date {
            switch type {
            case .integer, .number, .real:
                self.init(key: date.timeInterval, value: value)
            case .string, .text:
                self.init(key: date.iso8601, value: value)
            default:
                self.init(key: key, value: value)
            }
        } else {
            self.init(key: key, value: value)
        }
    }

    static func == (left: ChoiceListItem, right: ChoiceListItem) -> Bool {
        return left.key == right.key && left.value == right.value
    }

    func hash(into hasher: inout Hasher) {
        if let hashable = key as? AnyHashable {
            hasher.combine(hashable)
        }
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
        return "\(key)$\(value)" // unique key used as tag in option row
    }
}

extension ChoiceListItem: ActionParameterEncodable {
    func encodeForActionParameter() -> Any {
        return self.key.value
    }
}
