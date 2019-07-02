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
            if let valueString = value as? String {
                switch self.type {
                case .date:
                    if let date = valueString.dateFromRFC3339 ?? valueString.simpleDate ?? valueString.dateFromISO8601 {
                        return date
                    }
                    switch valueString.lowercased().replacingOccurrences(of: " ", with: "") {
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
                case .time:
                    return TimeFormatter.simple.time(from: valueString) ?? TimeFormatter.short.time(from: valueString)
                case .bool, .boolean:
                    return valueString.boolValue || valueString == "true"
                case .integer:
                    return Int(valueString)
                case .number:
                    if let format = format, format.isIntRow {  // XXX crappy convert code... find a better place to do it
                        return Int(valueString)
                    }
                    return Double(valueString)
                default:
                    break
                }
            } else if let valueInt = value as? Int {
                switch self.type {
                    /*case .time:
                     return valueInt * 1000 if need convertion s to ms, but I do not thiknks so*/
                case .bool, .boolean:
                    return valueInt == 1
                case .number:
                    if let format = format, format.isIntRow { // XXX crappy convert code... find a better place to do it
                        return valueInt
                    }
                    return Double(valueInt)
                case .string:
                    return "\(valueInt)"
                default:
                    break
                }
            } else if let valueDouble = value as? Double {
                switch self.type {
                case .bool, .boolean:
                    return valueDouble == 1.0
                case .integer:
                    return Int(valueDouble)
                case .string:
                    return "\(valueDouble)"
                default:
                    break
                }
                if let format = format, format.isIntRow { // XXX crappy convert code... find a better place to do it
                    return Int(valueDouble)
                }
            }
            return value
        }
        if let field = self.defaultField {
            // compute default value according to a defined properties and context
            if let value = context.actionParameterValue(for: field) {
                if case .time = self.type {
                    if let value = value as? Double {
                        return value / 1000 // remove misslisecond to transform to timeInterval(seconde)
                    }
                }
                return value
            }
            logger.warning("Default field defined \(field) but not found in context \(context)")
        }
        return nil
    }
}

extension ActionParameterFormat {

    var isIntRow: Bool {
        switch self {
        case .spellOut:
            return true
        case .integer:
            return true
        default:
            return false
        }
    }
}
