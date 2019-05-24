//
//  Eureka+ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

import QMobileAPI

extension FormViewController: ActionParametersUI {
    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        guard let parameters = action.parameters else {
            completionHandler(.failure(.noParameters))
            return
        }
        let viewController = FormViewController(style: .grouped)

        let section = viewController.form +++ Section()
        for parameter in parameters {
            section +++ parameter.formRow()
        }

        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.show()
    }
}

extension ActionParameter {

    private var key: String {
        return self.name
    }

    func formRow() -> BaseRow {
        let row = self.baseRow()
        if let field = row as? FieldRowConformance {
            if let placeholder = self.placeholder {
                field.placeholder = placeholder
            }
        }
        row.baseValue = self.default
        row.title = self.label ?? self.shortLabel ?? self.name

        if self.mandatory {
            /*if let rowOf = row as? RowOf<Equatable> { // not generic?
             rowOf.add(rule: RuleRequired())
             }*/

            /*if let rowOf = row as? RowOf<String> {
             row.add(rule: RuleRequired())
             }*/
        }

        return row
    }

    private func baseRow() -> BaseRow { // swiftlint:disable:this function_body_length
        if let choiceList = choiceList {

            // XXX multiple interface to choose between list
            let choiceRow = SegmentedRow<String>(key)
            // var choiceRow = PushRow<String>(key)
            choiceRow.options = choiceList.map { "\($0)" }

            return choiceRow
        }

        if let format = format {
            switch format {
            case .url:
                return URLRow(key) {
                    $0.add(rule: RuleURL())
                }
            case .email:
                return EmailRow(key) {
                    $0.add(rule: RuleEmail())
                }
            case .textArea, .comment:
                return TextAreaRow(key)
            case .password:
                return PasswordRow(key)
            case .phone:
                return PhoneRow(key)
            case .zipCode:
                return ZipCodeRow(key)
            case .name:
                return NameRow(key)
            case .account:
                return AccountRow(key)
            case .spellOut:
                return IntRow(key) {
                    let formatter = NumberFormatter()
                    formatter.locale = .current
                    formatter.numberStyle = .spellOut
                    $0.formatter = formatter
                }
            case .scientific:
                return DecimalRow {
                    let formatter = NumberFormatter()
                    formatter.locale = .current
                    formatter.numberStyle = .scientific
                    $0.formatter = formatter
                }
            case .percent:
                return IntRow(key) {
                    let formatter = NumberFormatter()
                    formatter.locale = .current
                    formatter.numberStyle = .percent
                    $0.formatter = formatter
                }
            case .energy:
                return DecimalRow {
                    let formatter = EnergyFormatter()
                    $0.formatter = formatter
                }
            case .mass:
                return DecimalRow {
                    $0.formatter = MassFormatter()
                }
            case .dateLong:
                return DateRow {
                    let formatter = DateFormatter()
                    formatter.locale = .current
                    formatter.dateStyle = .long
                    $0.dateFormatter = formatter
                }
            case .dateShort:
                return DateRow {
                    let formatter = DateFormatter()
                    formatter.locale = .current
                    formatter.dateStyle = .short
                    $0.dateFormatter = formatter
                }
            case .dateMedium:
                return DateRow {
                    let formatter = DateFormatter()
                    formatter.locale = .current
                    formatter.dateStyle = .medium
                    $0.dateFormatter = formatter
                }
            }
        }

        switch self.type {
        case .bool, .boolean:
            return SwitchRow(key)
        case .integer:
            return IntRow(key)
        case .date:
            return DateRow(key)
        case .string, .text:
            return TextRow(key)
        case .number, .real:
            return DecimalRow(key)
        case .duration:
            return TimeRow(key)
        case .time:
            return TimeRow(key)
        case .picture, .image:
            return ImageRow(key)
        case .file, .blob:
            return TextRow(key)
        }
    }

}
