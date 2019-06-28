//
//  ActionParameter+Eureka.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

import QMobileAPI

// MARK: ActionParameter as Row
extension ActionParameter {

    var preferredLongLabelMandatory: String {
        var result = self.preferredLongLabel
        if mandatory {
            result += " *"
        }
        return result
    }

    // Create a row, fill value, add rules
    func formRow(onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow {
        let row: BaseRow = self.baseRow(onRowEvent: eventCallback)
        row.title = self.preferredLongLabelMandatory
        row.tag = self.name
        if row is DecimalRow {
            // row.validationOptions = .validatesOnBlur // ie. default one
        } else {
            row.validationOptions = .validatesOnChange // issue with decimal row https://project.4d.com/issues/108712
        }
        // Placeholder
        if let placeholder = self.placeholder {
            if let field = row as? FieldRowConformance {
                field.placeholder = placeholder
            } else if let field = row as? TextAreaRow /*TextAreaConformance private ;(*/ {
                field.placeholder = placeholder
            } else if let field = row as? NoValueDisplayTextConformance {
                field.noValueDisplayText = placeholder
            }
        }

        // Rules
        for rule in rules ?? [] {
            switch rule {
            case .mandatory:
                if let rowOf = row as? RowOfEquatable {
                    rowOf.setRequired()
                }
            case .min(let min):
                if let rowOf = row as? RowOfComparable {
                    rowOf.setGreaterOrEqual(than: min)
                } else if let rowOf = row as? IntRow { // XXX why row are not RowOfComparable ? if put I have Conformance of 'IntRow' to protocol 'RowOfComparable' was already stated in the type's module 'Eureka'
                    rowOf.setGreaterOrEqual(than: Int(min))
                } else if let rowOf = row as? DecimalRow {
                    rowOf.setGreaterOrEqual(than: min)
                } else {
                    logger.warning("Rule min(\(min) applyed to non comparable data \(row)")
                }
            case .max(let max):
                if let rowOf = row as? RowOfComparable {
                    rowOf.setSmallerOrEqual(than: max)
                } else if let rowOf = row as? IntRow {
                    rowOf.setSmallerOrEqual(than: Int(max))
                } else if let rowOf = row as? DecimalRow {
                    rowOf.setSmallerOrEqual(than: max)
                } else if let rowOf = row as? RatingRow {
                    rowOf.cosmosSettings.totalStars = Int(max)
                } else {
                    logger.warning("Rule max(\(max) applyed to non comparable data \(row)")
                }
            case .minLength(let length):
                if let rowOf = row as? RowOf<String> {
                    rowOf.add(rule: RuleMinLength(minLength: UInt(length)))
                }
            case .maxLength(let length):
                if let rowOf = row as? RowOf<String> {
                    rowOf.add(rule: RuleMaxLength(maxLength: UInt(length)))
                }
            case .exactLength(let length):
                if let rowOf = row as? RowOf<String> {
                    rowOf.add(rule: RuleExactLength(exactLength: UInt(length)))
                }
            case .regex(let regExpr):
                if let rowOf = row as? RowOf<String> {
                    rowOf.add(rule: RuleRegExp(regExpr: regExpr))
                }
            @unknown case _:
                continue
            }
        }

        return row
    }

    // Create a row according to format and type
    // params: onChange dirty way to pass action on change on all row, cannot be done on BaseRow or casted...
    private func baseRow(onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow { //swiftlint:disable:this function_body_length
        if let choiceList = choiceList, let choice = ChoiceList(choiceList: choiceList, type: type) {

            // XXX multiple interface to choose between list
            // let choiceRow = SegmentedRow<String>(name)
            // let choiceRow = MultipleSelectorRow<String>(name)
            // let choiceRow = PopoverSelectorRow<String>(name)
            // let actionSheet = ActionSheetRow<String>(name)
            let choiceRow = PushRow<ChoiceListItem>(name)
            choiceRow.selectorTitle = self.preferredShortLabel

            choiceRow.options = choice.options
            if let value = self.default, let defaultChoice = choice.choice(for: value) {
                choiceRow.value = defaultChoice
            }
            return choiceRow.onRowEvent(eventCallback)
        }

        if let format = format {
            switch format {
            case .url:
                return URLRow(name) { $0.add(rule: RuleURL()) }.onRowEvent(eventCallback)
            case .email:
                return EmailRow(name) { $0.add(rule: RuleEmail()) }.onRowEvent(eventCallback)
            case .textArea, .comment:
                return TextAreaRow(name).onRowEvent(eventCallback)
            case .password:
                return PasswordRow(name).onRowEvent(eventCallback)
            case .phone:
                return PhoneRow(name).onRowEvent(eventCallback)
            case .zipCode:
                return ZipCodeRow(name).onRowEvent(eventCallback)
            case .name:
                return NameRow(name).onRowEvent(eventCallback)
            case .duration:
                return CountDownTimeRow(name).onRowEvent(eventCallback)
            case .rating:
                return RatingRow(name).onRowEvent(eventCallback)
            case .stepper:
                let row = StepperRow(name)
                if let cellUI = row.cell?.stepper {
                    if let value = rules?.min {
                        cellUI.minimumValue = value
                    }
                    if let value = rules?.max {
                        cellUI.maximumValue = value
                    }
                }
                return row.onRowEvent(eventCallback)
            case .slider:
                let row = SliderRow(name)
                if let cellUI = row.cell?.slider {
                    if let value = rules?.min {
                        cellUI.minimumValue = Float(value)
                    }
                    if let value = rules?.max {
                        cellUI.maximumValue = Float(value)
                    }
                }
                row.steps = 1
                return row.onRowEvent(eventCallback)
            case .check:
                return CheckRow(name).onRowEvent(eventCallback)
            case .switch:
                return SwitchRow(name).onRowEvent(eventCallback)
            case .account:
                return AccountRow(name).onRowEvent(eventCallback)
            case .spellOut, .integer:
                return IntRow(name) { $0.formatter = format.formatter }.onRowEvent(eventCallback)
            case .scientific, .percent, .energy, .mass:
                return DecimalRow(name) { $0.formatter = format.formatter }.onRowEvent(eventCallback)
            case .longDate, .shortDate, .mediumDate, .fullDate:
                return DateRow(name) { $0.dateFormatter = format.dateFormatter }.onRowEvent(eventCallback)
            }
        }
        // If no format return basic one from type
        return self.type.formRow(name, onRowEvent: eventCallback)
    }

}

extension Sequence where Element == ActionParameterRule {

    var min: Double? {
        for rule in self {
            if case let ActionParameterRule.min(value) = rule {
                return value
            }
        }
        return nil
    }
    var max: Double? {
        for rule in self {
            if case let ActionParameterRule.max(value) = rule {
                return value
            }
        }
        return nil
    }
}

// MARK: Manage row event

/// Eureka row event
enum RowEvent {
    case onChange
    case onCellSelection
    case onCellHighlightChanged
    case onRowValidationChanged
    case cellUpdate, cellSetup
}

typealias OnRowEventCallback = (BaseCell?, BaseRow, RowEvent) -> Void

extension RowType where Self: Eureka.BaseRow {
    /// Map all callback into one with event. Allow to pass generic code to BaseRow.
    func onRowEvent(_ callback: @escaping OnRowEventCallback) -> BaseRow {
        return self
            .cellSetup { callback($0 as BaseCell, $1 as BaseRow, .cellSetup) }
            .cellUpdate { callback($0 as BaseCell, $1 as BaseRow, .cellUpdate) }
            .onCellHighlightChanged { callback($0 as BaseCell, $1 as BaseRow, .onCellHighlightChanged) }
            .onRowValidationChanged { callback($0 as BaseCell, $1 as BaseRow, .onRowValidationChanged) }
            .onChange { callback(nil, $0 as BaseRow, .onChange) }
            .onCellSelection { callback($0 as BaseCell, $1 as BaseRow, .onCellSelection) }
    }
}

// MARK: ActionParameterType
extension ActionParameterType {

    func formRow(_ key: String, onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow {
        switch self {
        case .bool, .boolean:
            return SwitchRow(key).onRowEvent(eventCallback)
        case .integer:
            return IntRow(key).onRowEvent(eventCallback)
        case .date:
            return DateRow(key) { $0.dateFormatter = .mediumDate /* .rfc822*/ }.onRowEvent(eventCallback)
        case .string, .text:
            return TextRow(key).onRowEvent(eventCallback)
        case .number, .real:
            return DecimalRow(key) { $0.formatter = nil }.onRowEvent(eventCallback)
        case .time:
            return TimeIntervalRow(key).onRowEvent(eventCallback)
        case .picture, .image:
            return ImageRow(key).onRowEvent(eventCallback)
        case .file, .blob:
            return TextRow(key).onRowEvent(eventCallback)
        }
    }
}

// MARK: ActionParameterFormat
extension ActionParameterFormat {

    var formatter: Formatter? {
        switch self {
        case .percent, .spellOut, .scientific:
            let formatter = NumberFormatter()
            formatter.locale = .current
            if let numberStyle = self.numberStyle {
                formatter.numberStyle = numberStyle
            }
            return formatter
        case .energy:
            return EnergyFormatter()
        case .mass:
            return MassFormatter()
        case .longDate, .shortDate, .mediumDate, .fullDate:
            return dateFormatter
        default:
            return nil
        }
    }

    var numberStyle: NumberFormatter.Style? {
        switch self {
        case .spellOut:
            return .spellOut
        case .scientific:
            return .scientific
        case .percent:
            return .percent
        case .integer:
            return .none
        default:
            return nil
        }
    }

    var dateFormatter: DateFormatter? {
        if let dateStyle = self.dateStyle {
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.dateStyle = dateStyle
            return formatter
        }
        return nil
    }

    var dateStyle: DateFormatter.Style? {
        switch self {
        case .longDate:
            return .long
        case .shortDate:
            return .short
        case .mediumDate:
            return .medium
        case .fullDate:
            return .full
        default:
            return nil
        }
    }
}
