//
//  DeepLink.swift
//  QMobileUI
//
//  Created by phimage on 14/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import UIKit
import SwiftyJSON

public enum DeepLink {
    case main // onboarding?
    case mainNavigation
    case login
    case settings
    case table(String)
    case record(String, Any)
    case relation(String, Any, String) // ot change that to an history of deep link?

    // Return state from push notif informaton for instance
    static func from(_ userInfo: [AnyHashable: Any]) -> DeepLink? {
        if let table = userInfo["table"] as? String {
            if let record = userInfo["record"] {
                if let relationName = userInfo["relation"] as? String {
                    return .relation(table, record, relationName)
                } else {
                    return .record(table, record)
                }
            } else {
                return .table(table)
            }
        } else if let settings = userInfo["setting"] as? Bool, settings {
            return .settings
        } /*else if settings = userInfo["logout"] as? Bool, settings {
         return .login // need more things to do like invalidate token etc...
         }*/
        return nil
    }

    static func from(_ json: JSON) -> DeepLink? {
        if let table = json["table"].string {
            if json["record"].exists() {
                let record = json["record"].rawValue
                if let relation = json["relation"].string {
                    return .relation(table, record, relation)
                }
                return .record(table, record)
            }
            return .table(table)
        }
        return nil
    }

    /// url with path show?table= for lsit form
    /// url with path show?table=&record= for detal form
    static func from(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        // could check host, scheme? (if in app config)
        var pathComponents = components.path.components(separatedBy: "/")
        _ = pathComponents.removeFirst() // the first component is empty
        if pathComponents.isEmpty {
            return nil
        }
        switch pathComponents.removeFirst() {
        case "settings":
            return .settings
        case "show":
            guard let queryItems = components.queryItems else {
                return nil
            }
            guard let tableItem = queryItems.first(where: { $0.name == "table" }), let table = tableItem.value else {
                return nil
            }
            if let recordItem = queryItems.first(where: { $0.name == "record" }), let record = recordItem.value {
                return .record(table, record)
            } else {
                return .table(table)
            }
        default:
            return nil
        }
    }

    static func from(_ shortcutItem: UIApplicationShortcutItem) -> DeepLink? {
        /* if let data = shortcutItem.userInfo?["deeplink"] as? Data {
         // JSON decode? or decpdabme if done with
         let deeplinkData = try? JSONEncoder().encode(mydeeplinkInstance)
         UIMutableApplicationShortcutItem(type:...., userInfo: ["deeplink": deeplinkData as NSSecureCoding])
         -> put in UIApplication.shared.shortcutItems
         }*/
        return nil
    }
}

public protocol DeepLinkable {
    var deepLink: DeepLink? { get }
}

import QMobileAPI // for AnyCodable

extension DeepLink: Codable {

    enum CodingKeys: CodingKey {
        case main, mainNavigation, login, settings, table, record, relation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
        case .main:
            self = .main
        case .mainNavigation:
            self = .mainNavigation
        case .settings:
            self = .settings
        case .login:
            self = .login
        case .table:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .table)
            let tableName = try nestedContainer.decode(String.self)
            self = .table(tableName)
        case .record:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .table)
            let tableName = try nestedContainer.decode(String.self)
            guard let primaryKeyValue = try nestedContainer.decode(AnyCodable.self).wrapped else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode deepLink primary key value."
                    )
                )
            }
            self = .record(tableName, primaryKeyValue)
        case .relation:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .relation)
            let tableName = try nestedContainer.decode(String.self)
            guard let primaryKeyValue = try nestedContainer.decode(AnyCodable.self).wrapped else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode deepLink primary key value."
                    )
                )
            }
            let relationName = try nestedContainer.decode(String.self)
            self = .relation(tableName, primaryKeyValue, relationName)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode deepLink."
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .main:
            try container.encode(true, forKey: .main)
        case .mainNavigation:
            try container.encode(true, forKey: .mainNavigation)
        case .settings:
            try container.encode(true, forKey: .settings)
        case .login:
            try container.encode(true, forKey: .login)
        case .table(let tableName):
            try container.encode(tableName, forKey: .table)
        case .record(let tableName, let recordPrimaryKey):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .record)
            try nestedContainer.encode(tableName)
            try nestedContainer.encode(AnyCodable(recordPrimaryKey))
        case .relation(let tableName, let recordPrimaryKey, let relationName):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .relation)
            try nestedContainer.encode(tableName)
            try nestedContainer.encode(AnyCodable(recordPrimaryKey))
            try nestedContainer.encode(relationName)
        }
    }
}
