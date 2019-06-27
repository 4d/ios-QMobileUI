//
//  ChoiceListItem.swift
//  QMobileUI
//
//  Created by Eric Marchand on 27/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

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
