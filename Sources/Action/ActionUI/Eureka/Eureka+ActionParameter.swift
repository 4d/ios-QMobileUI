//
//  ActionParameter+Eureka.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

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

    /// Create a row, fill value, add rules
    func formRow(onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow {
        let row: BaseRow = self.baseRow(onRowEvent: eventCallback)
        row.title = self.preferredLongLabelMandatory
        row.tag = self.name
        if row is DecimalRow {
             row.validationOptions = .validatesOnBlur // ie. default one
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
        applyRules(row)

        return row
    }

    fileprivate func applyRules(_ row: BaseRow) {
        for rule in rules ?? [] {
            row.applyRule(rule)
        }

        if let rowOf = row as? StepperRow, let cellUI = rowOf.cell?.stepper {
            if let value = rules?.min {
                cellUI.minimumValue = value
            }
            if let value = rules?.max {
                cellUI.maximumValue = value
            }
        } else if let rowOf = row as? SliderRow, let cellUI = rowOf.cell?.slider {
            if let value = rules?.min {
                cellUI.minimumValue = Float(value)
            }
            if let value = rules?.max {
                cellUI.maximumValue = Float(value)
            }
        }
    }

    // Create a row according to format and type
    // params: onChange dirty way to pass action on change on all row, cannot be done on BaseRow or casted...
    private func baseRow(onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow { // swiftlint:disable:this function_body_length
        if let choiceList = choiceList, let choice = ChoiceList(choiceList: choiceList, type: type) {
            switch defaultChoiceFormat(format) {
            case .popover:
                return PopoverSelectorRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
            case .segmented:
                return SegmentedRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
            case .push:
                return PushRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
            case .sheet:
                return ActionSheetRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
            case .picker:
                return PickerRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
            default:
                assertionFailure("Must not occurs, a correct default type must have been chosen")
                return PushRow<ChoiceListItem>(name)
                    .fillOptions(choiceList: choice, parameter: self)
                    .onRowEvent(eventCallback)
                
            }
        }

        if let format = format, let row = format.formRow(name, onRowEvent: eventCallback) {
            return row
        }
        // If no format return basic one from type
        return self.type.formRow(name, onRowEvent: eventCallback)
    }

    
    private func defaultChoiceFormat(_ format: ActionParameterFormat?) -> ActionParameterFormat {
        if let format = format, format.isChoiceList {
            return format
        }
        return ActionParameterFormat.defaultChoiceListFormat
    }
}

import Prephirences
extension ActionParameterFormat {
    var isChoiceList: Bool {
        switch self {
        case .push, .popover, .segmented, .sheet, .picker:
            return true
        default:
            return false
        }
    }

    static var defaultChoiceListFormat: ActionParameterFormat {
        let value: ActionParameterFormat? = Prephirences.sharedInstance.rawRepresentable(forKey: "action.choiceList.defaultFormatter")
        return value ?? .push
    }
}

extension OptionsProviderRow where Self: Eureka.BaseRow, Self.OptionsProviderType.Option == ChoiceListItem, Self.Cell.Value == ChoiceListItem {

    /// Fill this type of row with choice list
    func fillOptions(choiceList: ChoiceList, parameter: ActionParameter) -> Self {
        switch parameter.type {
        case .bool, .boolean:
            self.options = choiceList.boolOptions
        default:
            self.options = choiceList.options
        }
        if let value = parameter.default, let defaultChoice = choiceList.choice(for: value) {
            self.value = defaultChoice
        }
        return self
    }
}
extension PickerRow: OptionsProviderRow {
    public typealias OptionsProviderType = OptionsProvider<Cell.Value>
    public var optionsProvider: OptionsProvider<Cell.Value>? {
        get {
            return .array(self.options)
        }
        set(newValue) {
            switch newValue {
            case .array(let array):
                if let array = array {
                    self.options = array
                }
            default:
                break
            }
        }
    }
}

// MARK: Manage row event

/// Eureka row event
public enum RowEvent {
    case onChange
    case onCellSelection
    case onCellHighlightChanged
    case onRowValidationChanged
    case cellUpdate, cellSetup
}

public typealias OnRowEventCallback = (BaseCell?, BaseRow, RowEvent) -> Void

public extension RowType where Self: Eureka.BaseRow {
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

// MARK: Create rows from type and formats

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

extension ActionParameterFormat {

    func formRow(_ key: String, onRowEvent eventCallback: @escaping OnRowEventCallback) -> BaseRow? { // swiftlint:disable:this function_body_length
        let format = self
        switch format {
        case .url:
            return URLRow(key) { $0.add(rule: RuleURL()) }.onRowEvent(eventCallback)
        case .email:
            return EmailRow(key) { $0.add(rule: RuleEmail()) }.onRowEvent(eventCallback)
        case .textArea, .comment:
            return TextAreaRow(key) {
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }.onRowEvent(eventCallback)
        case .password:
            return PasswordRow(key).onRowEvent(eventCallback)
        case .phone:
            return PhoneRow(key).onRowEvent(eventCallback)
        case .zipCode:
            return ZipCodeRow(key).onRowEvent(eventCallback)
        case .name:
            return NameRow(key).onRowEvent(eventCallback)
        case .duration:
            return CountDownTimeRow(key).onRowEvent(eventCallback)
        case .rating:
            return RatingRow(key).onRowEvent(eventCallback)
        case .barcode:
            return BarcodeScannerRow(key).onRowEvent(eventCallback)
        case .signature:
            return SignatureViewRow(key).onRowEvent(eventCallback)
        case .camera:
            return ImageRow(key) { $0.sourceTypes = .camera }.onRowEvent(eventCallback)
        case .photoLibrary:
            return ImageRow(key) { $0.sourceTypes = .photoLibrary }.onRowEvent(eventCallback)
        case .document:
            return ImageRow(key) { $0.sourceTypes = .document }.onRowEvent(eventCallback)
        case .ocr:
            return OCRRow(key).onRowEvent(eventCallback)
        case .location:
            return LocationRow(key).onRowEvent(eventCallback)
        case .stepper:
            return StepperRow(key).onRowEvent(eventCallback)
        case .slider:
            return SliderRow(key) { $0.steps = 1 }.onRowEvent(eventCallback)
        case .check:
            return CheckRow(key).onRowEvent(eventCallback)
        case .switch:
            return SwitchRow(key).onRowEvent(eventCallback)
        case .account:
            return AccountRow(key).onRowEvent(eventCallback)
        case .spellOut, .integer: // See isIntRow()
            return IntRow(key) { $0.formatter = format.formatter }.onRowEvent(eventCallback)
        case .scientific, .percent, .energy, .mass:
            return DecimalRow(key) { $0.formatter = format.formatter }.onRowEvent(eventCallback)
        case .longDate, .shortDate, .mediumDate, .fullDate:
            return DateWheelRow(key) { $0.dateFormatter = format.dateFormatter }.onRowEvent(eventCallback)
        case .push, .segmented, .popover, .sheet, .picker: // isChoiceList
            return nil // must have been taken into account before if ChoiceList defined
        case .custom(let string):
            if let builder = UIApplication.shared.delegate as? ActionParameterCustomFormatRowBuilder {
                if let row = builder.buildActionParameterCustomFormatRow(key: key, format: string, onRowEvent: eventCallback) {
                    return row
                }
            }
            if let app = UIApplication.shared as? QApplication {
                for service in app.services.services {
                    if let builder = service as? ActionParameterCustomFormatRowBuilder {
                        if let row = builder.buildActionParameterCustomFormatRow(key: key, format: string, onRowEvent: eventCallback) {
                            return row
                        }
                    }
                }
            }
            return nil
        }
    }

}

final class DateWheelRow: _DateRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
        self.cell.datePicker.preferredDatePickerStyle = .wheels
    }
}

/// base type of custom row
public typealias ActionParameterCustomFormatRowType = BaseRow

/// Protocol that could be implemented by AppDelegate or one ApplicationService to create custom action parameter format row.
public protocol ActionParameterCustomFormatRowBuilder {

    /**
     * Build a row according to format name.
     *
     * @param key : data key, ie. field name
     * @param format: the custom format name
     * @param onRowEvent: a callback that you must call on each row you build. If your row is RowType, then you could do `.onRowEvent(eventCallback)`
     *
     * @return the row or nil if format not taken into account.
     */
    func buildActionParameterCustomFormatRow(key: String, format: String, onRowEvent eventCallback: @escaping OnRowEventCallback) -> ActionParameterCustomFormatRowType?
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
            return NumberFormatter.Style.none
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

// MARK: - Rules

extension BaseRow {
    fileprivate func applyRule(_ rule: ActionParameterRule) { // swiftlint:disable:this function_body_length
        let row = self
        switch rule {
        case .mandatory:
            if let rowOf = row as? RowOfEquatable {
                rowOf.setRequired()
            }
        case .min(let min):
            if let rowOf = row as? IntRow {
                rowOf.setGreaterOrEqual(than: Int(min))
            } else if let rowOf = row as? DecimalRow {
                rowOf.setGreaterOrEqual(than: min)
            } else if let rowOf = row as? _TimeIntervalFieldRow {
                rowOf.setGreaterOrEqual(than: min)
                rowOf.minimumTime = min
            } else if let rowOf = row as? RowOfComparable {
                // row become  RowOfComparable now, a fix in swit language, but there issue with type casting
                // if int, we must convert to int
                rowOf.setGreaterOrEqual(than: min)
                if let timeRow = row as? _TimeIntervalFieldRow {
                    timeRow.minimumTime = min
                }
            } else {
                logger.warning("Rule min(\(min) applyed to non comparable data \(row)")
            }
        case .max(let max):
             if let rowOf = row as? IntRow {
                rowOf.setSmallerOrEqual(than: Int(max))
            } else if let rowOf = row as? DecimalRow {
                rowOf.setSmallerOrEqual(than: max)
            } else if let rowOf = row as? RatingRow {
                rowOf.cosmosSettings.totalStars = Int(max)
            } else if let rowOf = row as? _TimeIntervalFieldRow {
                rowOf.setSmallerOrEqual(than: max)
                rowOf.maximumTime = max
            } else if let rowOf = row as? RowOfComparable {
                rowOf.setSmallerOrEqual(than: max)
                if let timeRow = row as? _TimeIntervalFieldRow {
                    timeRow.maximumTime = max
                }
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
                if let terminationIndex = regExpr.lastIndex(of: "$"), regExpr[regExpr.index(terminationIndex, offsetBy: -1)] != "\\" {
                    let nextIndex = regExpr.index(terminationIndex, offsetBy: 1)
                    let newRegexExpr = String(regExpr[..<nextIndex])
                    let msg = String(regExpr[nextIndex...])
                    rowOf.add(rule: RuleRegExp(regExpr: newRegexExpr, msg: msg))
                } else {
                    rowOf.add(rule: RuleRegExp(regExpr: regExpr))
                }
            }
        case .isMultipleOf(let divideBy):
            if let rowOf = row as? RowOfIsMultipleOf {
                if let timeRow = row as? _TimeIntervalFieldRow {
                    timeRow.minuteInterval = Int(divideBy / 60)
                    rowOf.setMultiple(of: divideBy, msg: "Field value must be a multiple of \(divideBy/60) minutes")
                } else {
                    rowOf.setMultiple(of: divideBy, msg: nil)
                }
            } else if let rowOf = row as? IntRow { // not clean to do all this cast... maybe no more necessary
                rowOf.setMultiple(of: divideBy, msg: nil)
            } else if let rowOf = row as? DecimalRow {
                rowOf.setMultiple(of: divideBy, msg: nil)
            } else if let rowOf = row as? _TimeIntervalFieldRow {
                rowOf.setMultiple(of: divideBy, msg: nil)
            } else {
                logger.warning("Rule isMultipleOf(\(divideBy) applyed to non dividable data \(row)")
            }
        }
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
    var multipleOf: Double? {
        for rule in self {
            if case let ActionParameterRule.isMultipleOf(value) = rule {
                return value
            }
        }
        return nil
    }
}
