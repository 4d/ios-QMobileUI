//
//  ActionRequest+UI.swift
//  QMobileUI
//
//  Created by emarchand on 24/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI

extension ActionRequest {
    func statusImage(color: Bool) -> String {
        if color {
            switch state {
            case .cancelled:
                return "🚫"
            case .executing:
                return " " // replaced by spinner
            /*case .pending:
                return "⏸"*/
            case .ready:
                return "🆕"
            case .finished:
                switch result! {
                case .success(let value):
                    if value.success {
                        return "✅"
                    } else {
                        return "⚠️"
                    }
                case .failure:
                    return "❌"
                }
            }
        }
        switch state {
        case .cancelled:
            return "⌀"
        case .executing:
            return " " // replaced by spinner
        /*case .pending:
            return "‖"*/
        case .ready:
            return "🆕"
        case .finished:
            switch result! {
            case .success(let value):
                if value.success {
                    return "✓"
                } else {
                    return "⚠"
                }
            case .failure:
                return "x"
            }
        }
    }
}

extension ActionRequest {
    public var summary: String {
        if let statusText = statusText {
            return statusText
        }
        var summary = ""
        /*if let parameters = self.contextParameters {
         summary += parameters.values.compactMap({$0 as? String}).joined(separator: ",")
         }*/
        if let parameters = self.actionParameters, let definitions: [ActionParameter] = self.action.parameters {
            let definitionsMap: [String: ActionParameter] = Dictionary(uniqueKeysWithValues: definitions.map {($0.name, $0) })
            /*if self.contextParameters != nil {
             summary += ","
             }*/
            var values: [Any] = []
            for (key, value) in parameters {

                if let definition = definitionsMap[key] {
                    switch definition.type {
                    case .date:
                        if let string = value as? String,
                           let date = DateFormatter.simpleDate.date(from: string) {
                            values.append(DateFormatter.shortDate.string(from: date))
                        } else if let date = value as? Date {
                            values.append(DateFormatter.shortDate.string(from: date))
                        } else {
                            values.append(value)
                        }
                    case .time:
                        if let format = definition.format, case .duration = format {
                            if let number = value as? Double {
                                let dateComponents = Calendar.iso8601GreenwichMeanTime.dateComponents([.hour, .minute/*, .second*/], from: Date(timeInterval: number))
                                values.append(DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "") ?? value)

                            } else {
                                values.append(value)
                            }

                        } else {
                            if let number = value as? Int {
                                values.append(TimeFormatter.short.string(from: number))
                            } else if let number = value as? Double {
                                values.append(TimeFormatter.short.string(from: number))
                            } else {
                                values.append(value)
                            }
                        }
                    case .number, .real:
                        values.append("\(value)")
                    case .bool, .boolean:
                        if let format = definition.format, let value = value as? Bool {
                            if case .check = format {
                                values.append("\(value ? "✓": "")")
                            } else  if case .switch = format {
                                values.append("\(value ? "on": "off")")
                            }
                        } else {
                            values.append("\(value)")
                        }
                    default:
                        values.append(value)
                    }

                } else {
                    values.append(value)
                }
            }
            summary += values.compactMap({$0 as? String}).joined(separator: ",")
        }
        return summary
    }
}
