//
//  AnyWrapped.swift
//  QMobileUI
//
//  Created by Eric Marchand on 27/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import struct QMobileAPI.AnyCodable

// Protocol to unwrap internal value.
protocol AnyWrapped {
    /// The value wrapped by this instance.
    var wrapped: Any? { get }
}
extension AnyHashable: AnyWrapped {
    var wrapped: Any? {
        return base
    }
}

extension AnyCodable: AnyWrapped {
    var wrapped: Any? {
        return value
    }
    var codable: AnyCodable? {
        return self
    }
}
extension Optional: AnyWrapped {
    var wrapped: Any? {
        switch self {
        case .some(let wrapped):
            return wrapped
        case .none:
            return nil
        }
    }
}

extension AnyWrapped {
    var codable: AnyCodable {
        return AnyCodable(wrapped)
    }
}
