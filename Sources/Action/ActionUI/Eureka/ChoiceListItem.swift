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

/// Represent a choice in choice list
struct ChoiceListItem: Equatable {
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

extension ChoiceListItem: ActionParameterEncodable {
    func encodeForActionParameter() -> Any {
        return self.key.value
    }
}
