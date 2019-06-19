//
//  ActionContext.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

/// An action context provide parameters for action.
public protocol ActionContext {

    /// Provide parameters for the action.
    func actionParameters(action: Action) -> ActionParameters?

    /// Provide value for a field.
    func actionParameterValue(for field: String) -> Any?

}

public extension ActionContext {

    func actionParameterValue(for field: String) -> Any? {
        return nil
    }
}

/// Protocol to define class which could provide `ActionContext`
public protocol ActionContextProvider {

    func actionContext() -> ActionContext?
}

/// Some well known key for ActionParameters (not public yet)
struct ActionParametersKey {
    static let table = "dataClass"
    static let record = "entity"
    static let primaryKey = "primaryKey"
}

extension ActionParameter {

    public func defaultValue(with context: ActionContext) -> Any? {
        if let value = self.default?.value {
            if case .date = self.type {
                if let dateString = value as? String {
                    if let date = dateString.dateFromRFC3339 ?? dateString.simpleDate ?? dateString.dateFromISO8601 {
                        return date
                    }
                    switch dateString.lowercased().replacingOccurrences(of: " ", with: "") {
                    case "today":
                        return Date()
                    case "yesterday":
                        return Date.yesterday
                    case "tomorrow":
                        return Date.tomorrow
                    case "twodaysago":
                        return Date.twoDaysAgo
                    case "firstDayOfMonth":
                        return Date.firstDayOfMonth
                    default:
                        break
                    }
                }
            }
            return value
        }
        if let field = self.defaultField {
             // compute default value according to a defined properties and context
            return context.actionParameterValue(for: field)
        }
        return nil
    }
}
