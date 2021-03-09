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
            case .completed:
                switch result! {
                case .success(let value):
                    if value.success {
                        return "✅"
                    } else {
                        return "⚠️"
                    }
                case .failure:
                    return "‼️"
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
        case .completed:
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

    var summary: String {
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
            for parameter in self.action.parameters ?? [] {
                let key = parameter.name
                guard let value =  parameters[key] else {
                    continue
                }
                if let definition = definitionsMap[key], let value = definition.sumary(for: value) {
                    values.append(value)
                } else {
                    values.append(value)
                }
            }
            summary += values.compactMap({$0 as? String}).joined(separator: ",")
        }
        return summary
    }

    var title: String {
        var tableName = self.tableName
        tableName = ApplicationDataStore.instance.dataStore.tableInfo(for: tableName)?.originalName ?? tableName
        return "\(tableName.capitalized()): \(shortTitle)"
    }

    var shortTitle: String {
        return "\(action.preferredLongLabel.replacingOccurrences(of: "...", with: "").replacingOccurrences(of: "…", with: ""))"
    }
}

extension ActionParameter {

    fileprivate func sumary(for value: Any) -> String? {
        if let choiceList = self.choiceList, let choice = ChoiceList(choiceList: choiceList, type: self.type) {
            if let value = choice.choice(for: AnyCodable(castData(value))) {  // find value in list
                return "\(value.value)"
            }
            if let value = choice.choice(for: AnyCodable(value)) {  // find value in list
                return "\(value.value)"
            }
        }

        switch self.type {
        case .date:
            if let string = value as? String,
               let date = DateFormatter.simpleDate.date(from: string) {
               return DateFormatter.shortDate.string(from: date)
            } else if let date = value as? Date {
                return DateFormatter.shortDate.string(from: date)
            } else {
               return nil
            }
        case .time:
            if let format = self.format, case .duration = format {
                if let number = value as? Double {
                    let dateComponents = Calendar.iso8601GreenwichMeanTime.dateComponents([.hour, .minute/*, .second*/], from: Date(timeInterval: number))
                    return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "")
                } else {
                    return nil
                }

            } else {
                if let number = value as? Int {
                    return TimeFormatter.short.string(from: number)
                } else if let number = value as? Double {
                    return TimeFormatter.short.string(from: number)
                } else {
                    return nil
                }
            }
        case .number, .real:
            return "\(value)"
        case .bool, .boolean:
            if let format = self.format, let value = value as? Bool {
                if case .check = format {
                    return "\(value ? "☑": "☐")"
                } else  if case .switch = format {
                    return "\(value ? "on": "off")"
                }
            } else {
                return "\(value)"
            }
        default:
            return nil
        }
        return nil
    }
}
