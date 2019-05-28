//
//  Eureka+ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka
import SwiftMessages

import QMobileAPI

class ActionFormViewController: FormViewController {

    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = UIView()
    var completionHandler: CompletionHandler = { result in }
    var parameters: [ActionParameter] = []

    convenience init(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ parameters: [ActionParameter], _ completionHandler: @escaping CompletionHandler) {
        self.init(style: .grouped)
        self.action = action
        self.actionUI = actionUI
        self.context = context
        self.parameters = parameters
        self.completionHandler = completionHandler
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let section = self.form +++ Section()
        var values: [String: Any?] = [:]
        for parameter in parameters {
            section +++ parameter.formRow()
            values[parameter.key] = parameter.defaultValue(with: context)
        }
        values = values.mapValues { ($0 as? AnyCodable)?.value ?? $0 }
        self.form.setValues(values)

        let backItem = UIBarButtonItem(image: UIImage(named: "previous"), style: .plain, target: self, action: #selector(dismissAction))
        // let backItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissAction)) // LOCALIZE
        self.navigationItem.add(where: .left, item: backItem)

        let doneItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(buttonAction)) // LOCALIZE
        self.navigationItem.add(where: .right, item: doneItem)

        self.navigationItem.title = self.action.preferredShortLabel
    }

    @objc func buttonAction(sender: UIButton!) {
        let errors = self.form.validate()
        if let error = errors.first {
            SwiftMessages.error(error: error)
            // show on field him self
        } else {
            let values = self.form.values()

            // XXX maybe dismiss only after receive information
            self.dismiss(animated: true) {
                self.completionHandler(.success((self.action, self.actionUI, self.context, values as ActionParameters)))
            }
        }
    }

    @objc func dismissAction(sender: Any!) {
        self.dismiss(animated: true) {
            self.completionHandler(.failure(.userCancel))
        }
    }
}
/*
extension Eureka.Form {

    @discardableResult
    public func validate(includeHidden: Bool = false, includeDisabled: Bool = true) -> [ValidationError] {
        let rowsWithHiddenFilter = includeHidden ? self.allRows : self.rows
        let rowsWithDisabledFilter = includeDisabled ? rowsWithHiddenFilter : rowsWithHiddenFilter.filter { $0.isDisabled != true }

        return rowsWithDisabledFilter.reduce([ValidationError]()) { res, row in
            var res = res
            let errors = row.validate()
            res.append(contentsOf: errors)
            let cell = row.baseCell
            /* cell?.detailTextLabel?.text = errors.map { $0.msg }.joined(separator: ",")
             cell?.detailTextLabel?.isHidden = false
             cell?.detailTextLabel?.textAlignment = .left
             cell?.detailTextLabel?.textColor = .red*/

            if !row.isValid {
                cell?.textLabel?.textColor = .red
            }
            return res
        }
    }
}*/

extension ValidationError: LocalizedError {
    public var errorDescription: String? { return msg }

    public var failureReason: String? { return nil }

    public var recoverySuggestion: String? { return nil }

    public var helpAnchor: String? { return nil }
}

extension ActionFormViewController: ActionParametersUI {

    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        guard let parameters = action.parameters else {
            completionHandler(.failure(.noParameters))
            return
        }
        let viewController: ActionFormViewController = ActionFormViewController(action, actionUI, context, parameters, completionHandler)

        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        navigationController.show()
    }
}

extension ActionParameter {

    fileprivate var key: String {
        return self.name
    }

    func formRow() -> BaseRow {
        let row: BaseRow = self.baseRow()
        if let field = row as? FieldRowConformance {
            if let placeholder = self.placeholder {
                field.placeholder = placeholder
            }
        }
        row.baseValue = self.default
        row.title = self.label ?? self.shortLabel ?? self.name

        if self.mandatory {
            if let rowOf = row as? RowOfEquatable {
                rowOf.setRequired()
            }
            row.validationOptions = .validatesOnChange

            if let format = format {
                switch format {
                case .email:
                    row.validationOptions = .validatesOnChangeAfterBlurred
                default:
                    break
                }
            }
        }
        if let min = self.min {
            if let rowOf = row as? RowOfComparable {
                rowOf.setGreaterOrEqual(than: min)
            }
        }
        if let max = self.max {
            if let rowOf = row as? RowOfComparable {
                rowOf.setSmallerOrEqual(than: max)
            }
        }

        /*row.cellUpdate({ cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        })*/

        return row
    }

    private func baseRow() -> BaseRow {
        if let choiceList = choiceList {
            // XXX multiple interface to choose between list
            let choiceRow = SegmentedRow<String>(key)
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
            case .countDown:
                return CountDownRow(key)
            case .rating:
                return RatingRow(key)
            case .account:
                return AccountRow(key)
            case .spellOut:
                return IntRow(key) {
                    $0.formatter = format.formatter
                }
            case .scientific, .percent, .energy, .mass:
                return DecimalRow {
                    $0.formatter = format.formatter
                }
            case .dateLong, .dateShort, .dateMedium:
                return DateRow {
                    $0.dateFormatter = format.dateFormatter
                }
            }
        }
        // If no format return basic one from type
        return self.type.formRow(key)
    }

}

protocol RowOfEquatable: BaseRowType {
    func setRequired(_ value: Bool)
}
extension RowOfEquatable {

    func setRequired() {
        setRequired(true)
    }
}

extension RowOf: RowOfEquatable where T: Equatable {
    func setRequired(_ value: Bool) {
        self.remove(ruleWithIdentifier: "actionParameterRequired")
        if value {
            self.add(rule: RuleRequired(id: "actionParameterRequired"))
        }
    }
}

protocol RowOfComparable: BaseRowType {
    func setGreater(than value: Any?)
    func setGreaterOrEqual(than value: Any?)
    func setSmaller(than value: Any?)
    func setSmallerOrEqual(than value: Any?)
}

extension RowOf: RowOfComparable where T: Comparable {
    func setGreater(than value: Any?) { // , orEqual: Bool = false
        self.remove(ruleWithIdentifier: "actionParameterGreaterThan")
        if let value = value as? T {
            self.add(rule: RuleGreaterThan(min: value, id: "actionParameterGreaterThan"))
        }
    }
    func setGreaterOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterGreaterThan")
        if let value = value as? T {
            self.add(rule: RuleGreaterOrEqualThan(min: value, id: "actionParameterGreaterThan"))
        }
    }
    func setSmaller(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerThan(max: value, id: "actionParameterSmallerThan"))
        }
    }
    func setSmallerOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerOrEqualThan(max: value, id: "actionParameterSmallerThan"))
        }
    }
}

extension ActionParameterType {
    func formRow(_ key: String) -> BaseRow {
        switch self {
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
