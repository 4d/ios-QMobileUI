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
    func actionContextParameters() -> ActionParameters?

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

extension ActionParameter {

    // Do the better to cast data according to action parameter type.
    func castData(_ value: Any) -> Any? {
        if let valueString = value as? String {
            switch self.type {
            case .date:
                if let date = valueString.dateFromRFC3339 ?? valueString.simpleDate ?? valueString.dateFromISO8601 ?? valueString.dateFromName {
                    return date
                }
            case .time:
                return TimeFormatter.time(from: valueString)
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

    /// Get default value for this parameters.
    ///
    /// - Parameters:
    ///     - context: the context to get data values if `defaultField` defined.
    public func defaultValue(with context: ActionContext) -> Any? { // swiftlint:disable:this function_body_length
        if let value = self.default?.value {
            let castedData = castData(value)
            if let choiceList = choiceList, let choice = ChoiceList(choiceList: choiceList, type: type) {
                if let value = choice.choice(for: AnyCodable(castedData)) {  // find value in list
                    return value
                }
            }
            return castedData
        } else if let field = self.defaultField {
            // compute default value according to a defined properties and context
            if let value = context.actionParameterValue(for: field) {
                switch self.type {
                case .time:
                    if let value = value as? Double {
                        return value / 1000 // remove misslisecond to transform to timeInterval(seconde)
                    }
                case .image, .picture:
                    if let value = value as? [String: Any] {
                        if let imageResource = ApplicationImageCache.imageResource(for: value),
                            let image = ApplicationImageCache.retrieve(for: imageResource) {
                            return image
                        }
                    }
                default:
                    break
                }
                if let choiceList = choiceList, let choice = ChoiceList(choiceList: choiceList, type: type) {
                    if let value = choice.choice(for: AnyCodable(value)) { // find value in list
                        return value
                    }
                }
                return value
            }
            logger.warning("Default field defined \(field) but not found in context \(context)")
        } else if let actionRequest = context as? ActionRequest {

            actionRequest.decodeParameters() // alternative, get a new decoded object which respond to actionParameterValue(for: name)

            if let value = actionRequest.actionParameterValue(for: name) {
                switch self.type {
                case .time:
                    return value
                case .image, .picture:
                    if let value = value as? ImageUploadOperationInfo {
                        let result = value.awaitRetrieve()
                        switch result {
                        case .success(let imageResult):
                            return imageResult.image
                        case .failure:
                            break
                        }
                    }
                default:
                    break
                }
                if let choiceList = choiceList, let choice = ChoiceList(choiceList: choiceList, type: type) {
                    if let value = choice.choice(for: AnyCodable(value)) { // find value in list
                        return value
                    }
                }
                return value
            }
        }
        return nil
    }
}

extension ActionParameterFormat {

    /// Even if number, this format need integer data.
    var isIntRow: Bool {
        switch self {
        case .spellOut, .integer:
            return true
        default:
            return false
        }
    }
}

fileprivate extension TimeFormatter {

    private static let formatters: [TimeFormatter] = [.simple, .short, .hourMinute]
    static func time(from string: String) -> TimeInterval? {
        for formatter in formatters {
            if let value = formatter.time(from: string) {
                return value
            }
        }
        return nil
    }
}

extension String {

    /// Get date from "today", ...
    fileprivate var dateFromName: Date? {
        switch self.lowercased().replacingOccurrences(of: " ", with: "") {
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
            return nil
        }
    }
}
