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

class ActionFormViewController: FormViewController {

    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = ActionManager.instance
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
        self.navigationItem.add(where: .left, item: backItem)

        let doneItem = UIBarButtonItem(title: self.action.preferredShortLabel, style: .plain, target: self, action: #selector(buttonAction))
        self.navigationItem.add(where: .right, item: doneItem)
    }

    @objc func buttonAction(sender: UIButton!) {
        let errors = self.form.validate()
        if errors.isEmpty {
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

        return row
    }

    private func baseRow() -> BaseRow {
        if let choiceList = choiceList {
            // XXX multiple interface to choose between list
            let choiceRow = SegmentedRow<String>(key)
            // var choiceRow = PushRow<String>(key)
            choiceRow.options = choiceList.map { "\($0)" }

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
