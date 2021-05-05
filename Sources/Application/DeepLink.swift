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
    case navigation
    case login([String: String?])
    case settings
    case table(String)
    case record(String, Any)
    case relation(String, Any, String) // ot change that to an history of deep link?

    // Return state from push notif informaton for instance
    static func from(_ userInfo: [AnyHashable: Any]) -> DeepLink? {
        if let table = userInfo["dataClass"] as? String ?? userInfo["table"] as? String {
            if let record = userInfo["record"] ?? ((userInfo["entity"] as? [String: Any])?["primaryKey"]) {
                if let relationName = userInfo["relation"] as? String ?? userInfo["relationName"] as? String {
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
        if let table = json["dataClass"].string ?? json["table"].string {
            if json["record"].exists() {
                let record = json["record"].rawValue
                if let relation = json["relation"].string ?? json["relationName"].string {
                    return .relation(table, record, relation)
                }
                return .record(table, record)
            } else if json["entity"].exists() {
                let record = json["entity"]["primaryKey"].rawValue
                if let relation = json["relation"].string ?? json["relationName"].string {
                    return .relation(table, record, relation)
                }
                return .record(table, record)
            } else if json["entity.primaryKey"].exists() {
                let record = json["entity.primaryKey"].rawValue
                if let relation = json["relation"].string ?? json["relationName"].string {
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
        case "login":
            var parameters: [String: String?] = [:]
            for queryItem in components.queryItems ?? [] {
                parameters[queryItem.name] = queryItem.value
            }
            return .login(parameters)
        default:
            guard let queryItems = components.queryItems else {
                return nil
            }
            guard let tableItem = queryItems.first(where: { $0.name == "table" || $0.name.lowercased() == "dataclass" }), let table = tableItem.value else {
                return nil
            }
            if let recordItem = queryItems.first(where: { $0.name == "record" || $0.name.lowercased() == "entity.primarykey" }), let record = recordItem.value {
                if let relationItem = queryItems.first(where: { $0.name.lowercased() == "relationname" || $0.name == "relation"  }), let relationName = relationItem.value {
                    return .relation(table, record, relationName)
                }
                return .record(table, record)
            } else {
                return .table(table)
            }
        }
    }

    static func from(_ shortcutItem: UIApplicationShortcutItem) -> DeepLink? {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data {
            return try? JSONDecoder().decode(DeepLink.self, from: data)
            // UIMutableApplicationShortcutItem(type:...., userInfo: ["deeplink": deeplinkData as NSSecureCoding])   -> put in UIApplication.shared.shortcutItems
        }
        return nil
    }
}

/// Protocol to define element accessible by deep linking
public protocol DeepLinkable {

    /// The deep link associated value
    var deepLink: DeepLink? { get }
    /// Take a change to manage deep link data if already opened.
    func manage(deepLink: DeepLink)
}
public extension DeepLinkable {
    func manage(deepLink: DeepLink) {} // by default do nothing
}

import QMobileAPI // for AnyCodable

extension DeepLink: Codable {

    enum CodingKeys: CodingKey {
        case main, navigation, login, settings, table, record, relation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
        case .main:
            self = .main
        case .navigation:
            self = .navigation
        case .settings:
            self = .settings
        case .login:
            self = .login([:]) // TODO propert decoding/encoding of login deep linking, or consider that must not be save
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
        case .navigation:
            try container.encode(true, forKey: .navigation)
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

extension DeepLink: Equatable {

    public static func == (lhs: DeepLink, rhs: DeepLink) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main):
            return true
        case (.navigation, .navigation):
            return true
        case (.login, .login):
            return true
        case (.settings, .settings):
            return true
        case (let .table(table1), let .table(table2)):
            return table1 == table2
        case (let .record(table1, primary1), let .record(table2, primary2)):
            guard table1 == table2 else {
                return false
            }
            // suppose type of primary keys...
            if let primary1 = primary1 as? String, let primary2 = primary2 as? String {
                return primary1 == primary2
            }
            if let primary1 = primary1 as? Double, let primary2 = primary2 as? Double {
                return primary1 == primary2
            }
            if let primary1 = primary1 as? Int, let primary2 = primary2 as? Int {
                return primary1 == primary2
            }
            return false
        case (let .relation(table1, primary1, relation1), let .relation(table2, primary2, relation2)):
            guard table1 == table2 && relation1 == relation2 else {
                return false
            }
            // suppose type of primary keys...
            if let primary1 = primary1 as? String, let primary2 = primary2 as? String {
                return primary1 == primary2
            }
            if let primary1 = primary1 as? Double, let primary2 = primary2 as? Double {
                return primary1 == primary2
            }
            if let primary1 = primary1 as? Int, let primary2 = primary2 as? Int {
                return primary1 == primary2
            }
            return false
        default:
            return false
        }
    }

}

extension DeepLink {

    /// Expected previous deeplink page.
    var parent: DeepLink? {
        switch self {
        case .login, .navigation:
            return .main
        case .main:
            return nil
        case .settings:
            return .navigation
        case .table:
            return .navigation
        case .record(let table, _):
            return .table(table)
        case .relation(let table, let primaryKeyValue, _):
            return .record(table, primaryKeyValue)
        }
    }

    /// Expected hierarchy of deeplink page.
    var hierarchy: [DeepLink] {
        var hierarchy: [DeepLink] = []
        var current = self.parent // or self?
        while current != nil {
            if let theCurrent = current {
                hierarchy.append(theCurrent)
                current = theCurrent.parent
            }
        }
        return hierarchy
    }

}

extension UIViewController {
    var deepLinkHierarchy: [DeepLinkable]? {
        return self.hierarchy?.compactMap { $0 as? DeepLinkable }
    }
}
