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
    func formRow(onChange: @escaping (BaseRow) -> Void) -> BaseRow {
        let row: BaseRow = self.baseRow(onChange: onChange)
        row.title = self.preferredLongLabelMandatory
        row.tag = self.name

        // Placeholder
        if let field = row as? FieldRowConformance {
            if let placeholder = self.placeholder {
                field.placeholder = placeholder
            }
        }

        /*onRowValidationTests(row: row) { (_, _) in

        }*/

        // Rules
        for rule in rules ?? [] {
            switch rule {
            case .mandatory:
                if let rowOf = row as? RowOfEquatable {
                    rowOf.setRequired()
                }
               /* if let format = format {
                    switch format {
                    case .email:
                        row.validationOptions = .validatesOnChangeAfterBlurred
                    default:
                        break
                    }
                }*/
            case .min(let min):
                if let rowOf = row as? RowOfComparable {
                    rowOf.setGreaterOrEqual(than: min)
                } else if let rowOf = row as? IntRow { // XXX why row are not RowOfComparable ? if put I have Conformance of 'IntRow' to protocol 'RowOfComparable' was already stated in the type's module 'Eureka'
                    rowOf.setGreaterOrEqual(than: min)
                } else if let rowOf = row as? DecimalRow {
                    rowOf.setGreaterOrEqual(than: min)
                } else {
                    logger.warning("Rule min(\(min) applyed to non comparable data \(row)")
                }
            case .max(let max):
                if let rowOf = row as? RowOfComparable {
                    rowOf.setSmallerOrEqual(than: max)
                } else if let rowOf = row as? IntRow {
                    rowOf.setSmallerOrEqual(than: max)
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
            @unknown default:
                break
            }
        }

        /*row.cellUpdate({ cell, row in
         if !row.isValid {
         cell.titleLabel?.textColor = .red
         }
         })*/

        return row
    }

    // Create a row according to format and type
    // params: onChange dirty way to pass action on change on all row, cannot be done on BaseRow or casted...
    private func baseRow(onChange: @escaping (BaseRow) -> Void) -> BaseRow { //swiftlint:disable:this function_body_length
        if let choiceList = choiceList {
            // XXX multiple interface to choose between list
            let choiceRow = SegmentedRow<String>(name)
            // var choiceRow = PushRow<String>(key)
            if let choiceArray = choiceList.value as? [AnyCodable] {
                choiceRow.options = choiceArray.map { "\($0)" }
            } else if let choiceDictionary = choiceList.value as? [String: AnyCodable] {
                choiceRow.options = choiceDictionary.values.map { "\($0)" }
            }

            /*let actionSheet = ActionSheetRow<String>() {
             $0.title = "ActionSheetRow"
             $0.selectorTitle = "Pick a number"
             $0.options = ["One","Two","Three"]
             $0.value = "Two"    // initially selected
             }*/

            /*let row = PushRow<Emoji>() {
             $0.title = "PushRow"
             $0.options = [💁🏻, 🍐, 👦🏼, 🐗, 🐼, 🐻]
             $0.value = 👦🏼
             $0.selectorTitle = "Choose an Emoji!"
             }*/

            return choiceRow.onCellHighlightChanged { onChange($1 as BaseRow) }
        }

        if let format = format {
            switch format {
            case .url:
                return URLRow(name) {
                    $0.add(rule: RuleURL())
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            case .email:
                return EmailRow(name) {
                    $0.add(rule: RuleEmail())
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            case .textArea, .comment:
                return TextAreaRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .password:
                return PasswordRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .phone:
                return PhoneRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .zipCode:
                return ZipCodeRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .name:
                return NameRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .countDown:
                return CountDownRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .rating:
                return RatingRow(name) {
                    $0.text = ""
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            case .stepper:
                return StepperRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .slider:
                return SliderRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .check:
                return CheckRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .account:
                return AccountRow(name).onCellHighlightChanged { onChange($1 as BaseRow) }
            case .spellOut:
                return IntRow(name) {
                    $0.formatter = format.formatter
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            case .scientific, .percent, .energy, .mass:
                return DecimalRow {
                    $0.formatter = format.formatter
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            case .dateLong, .dateShort, .dateMedium:
                return DateRow {
                    $0.dateFormatter = format.dateFormatter
                }.onCellHighlightChanged { onChange($1 as BaseRow) }
            }
        }
        // If no format return basic one from type
        return self.type.formRow(name, onChange: onChange)
    }

}

// MARK: ActionParameterType
extension ActionParameterType {
    func formRow(_ key: String, onChange: @escaping (BaseRow) -> Void) -> BaseRow {
        switch self {
        case .bool, .boolean:
            return SwitchRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .integer:
            return IntRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .date:
            return DateRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .string, .text:
            return TextRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .number, .real:
            return DecimalRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .duration:
            return TimeRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .time:
            return TimeRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .picture, .image:
            return ImageRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
        case .file, .blob:
            return TextRow(key).onCellHighlightChanged { onChange($1 as BaseRow) }
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
            if let numberStyle =  self.numberStyle {
                formatter.numberStyle = numberStyle
            }
            return formatter
        case .energy:
            return EnergyFormatter()
        case .mass:
            return MassFormatter()
        case .dateLong, .dateShort, .dateMedium:
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
        default:
            return nil
        }
    }

    var dateFormatter: DateFormatter? {
        switch self {
        case .dateLong, .dateShort, .dateMedium:
            let formatter = DateFormatter()
            formatter.locale = .current
            if let dateStyle =  self.dateStyle {
                formatter.dateStyle = dateStyle
            }
            return formatter
        default:
            return nil
        }
    }
    var dateStyle: DateFormatter.Style? {
        switch self {
        case .dateLong:
            return .long
        case .dateShort:
            return .short
        case .dateMedium:
            return .medium
        default:
            return nil
        }
    }
}
