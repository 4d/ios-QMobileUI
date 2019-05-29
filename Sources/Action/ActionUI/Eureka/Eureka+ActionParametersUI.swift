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

// a table delegate to notify tap outside cell
protocol TapOutsideTableViewDelegate: UITableViewDelegate {
    func tableViewDidTapBelowCells(in tableView: UITableView)
}

// a table to notify tap outside cell
class TapOutsideTableView: UITableView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.indexPathForRow(at: point) == nil {
            if let delegate = self.delegate as? TapOutsideTableViewDelegate {
                delegate.tableViewDidTapBelowCells(in: self)
            }
        }
        return super.hitTest(point, with: event)
    }
}

struct ActionFormSettings { // XXX use settings
    static let oneSection = false
    static let sectionForTextArea = true
    static let errorAsDetail = false
    static let alertIfOneField = true
}

class ActionFormViewController: FormViewController {
    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = UIView()
    var completionHandler: CompletionHandler = { result in }
    var parameters: [ActionParameter] = []

    private var tableViewStyle: UITableView.Style = .grouped

    // MARK: Init

    convenience init(style: UITableView.Style, _ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ parameters: [ActionParameter], _ completionHandler: @escaping CompletionHandler) {
        self.init(style: style)
        self.action = action
        self.actionUI = actionUI
        self.context = context
        self.parameters = parameters
        self.completionHandler = completionHandler
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
        tableViewStyle = style
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func initNavigationBar() {
        // let backItem = UIBarButtonItem(image: UIImage(named: "previous"), style: .plain, target: self, action: #selector(cancelAction))
        // let backItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAction)) // LOCALIZE
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.add(where: .left, item: cancelItem)

        // let doneItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction)) // LOCALIZE
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.add(where: .right, item: doneItem)

        self.navigationItem.title = self.action.preferredShortLabel
        self.navigationController?.navigationBar.tintColor = .white
    }

    fileprivate func initDefaultValues() {
        var values: [String: Any?] = [:]
        for parameter in parameters {
            values[parameter.name] = parameter.defaultValue(with: context)
        }
        values = values.mapValues { ($0 as? AnyCodable)?.value ?? $0 }
        self.form.setValues(values)
    }

    /*override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     return super.tableView(tableView, heightForHeaderInSection: section)
     }*/
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    fileprivate func initRows() {
        if ActionFormSettings.oneSection {
            let section = self.form +++ Section()
            for parameter in parameters {
                let row = parameter.formRow()
                if ActionFormSettings.sectionForTextArea && row is TextAreaRow {
                    form +++ Section(parameter.preferredLongLabelMandatory) <<< row
                } else {
                    section +++ row
                }
            }
        } else {
            for parameter in parameters {
                let section = self.form +++ Section(parameter.preferredLongLabelMandatory) /*{ section in
                    var header = HeaderFooterView(stringLiteral: parameter.preferredLongLabelMandatory)
                    section.header = header
                    header.height = { 25 }
                }*/
                let row = parameter.formRow()
                row.title = nil
                section +++ row
            }
        }
    }

    // MARK: Life

    override func viewDidLoad() {
        tableView = TapOutsideTableView(frame: view.bounds, style: tableViewStyle)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.cellLayoutMarginsFollowReadableWidth = false

        super.viewDidLoad()

        if case .plain = tableViewStyle {
            tableView.tableFooterView = UIView()
        }

        initRows()
        initDefaultValues()
        initNavigationBar()

        navigationOptions = [.Enabled, .StopDisabledRow]
        animateScroll = true
        rowKeyboardSpacing = 20 // Leaves 20pt of space between the keyboard and the highlighted row after scrolling to an off screen row
    }

    // MARK: Actions

    @objc func doneAction(sender: UIButton!) {

        let errors = self.form.validateRows()
        if errors.isEmpty {
            for row in self.form.rows {
                row.removeValidationErrorRows()
            }
            let values = self.form.values()

            self.dismiss(animated: true) { // TODO: do not dismiss here, only according to action result
                self.completionHandler(.success((self.action, self.actionUI, self.context, values as ActionParameters)))
            }
        } else {
            // remove if no more errors
            for row in self.form.rows where row.validationErrors.isEmpty {
                row.removeValidationErrorRows()
            }
            // display errors
            for (row, rowErrors) in errors {
                row.display(errors: rowErrors)
            }
            // scroll to first row with errors
            let rows = self.form.rows.filter { !$0.validationErrors.isEmpty }
            if let row = rows.first {
                row.selectScrolling(animated: false)
            }
        }
    }

    @objc func cancelAction(sender: Any!) {
        self.dismiss(animated: true) {
            self.completionHandler(.failure(.userCancel))
        }
    }
}

extension Eureka.BaseRow {

    // Reset rows validation
    func display(errors: [ValidationError]) {
        if let error = errors.first {
            if let cell = self.baseCell {
                if ActionFormSettings.oneSection {
                    cell.textLabel?.backgroundColor = .red
                } else {
                    cell.borderColor = .red
                }
                if ActionFormSettings.errorAsDetail {
                    cell.detailTextLabel?.text = error.msg
                    cell.detailTextLabel?.textColor = .red
                } else {
                    addValidationErrorRows()
                }
            }
        }
        // XXX multiple errors?
    }

}

/*
 extension Form {

 static func installDefaultValidationHandlers() {
 TextRow.defaultCellUpdate = highlightCellLabelIfValidationFailed
 TextRow.defaultOnRowValidationChanged = showValidationErrors
 }

 private static func highlightCellLabelIfValidationFailed(cell: BaseCell, row: BaseRow) {
 if !row.isValid {
 cell.textLabel?.textColor = .red
 }
 }

 private static func showValidationErrors(cell: BaseCell, row: BaseRow) {
 row.removeValidationErrorRows()
 row.addValidationErrorRows()
 }
 }

 */
extension BaseRow {

    fileprivate func removeValidationErrorRows() {
        guard let rowIndex = indexPath?.row else { return }
        while section!.count > rowIndex + 1 && section?[rowIndex  + 1] is LabelRow {
            _ = section?.remove(at: rowIndex + 1)
        }
    }

    fileprivate func addValidationErrorRows() {
        removeValidationErrorRows() // XXX maybe recycle label to remove animation

        for (index, validationMsg) in validationErrors.map({ $0.msg }).enumerated() {
            let labelRow = LabelRow {
                $0.title = validationMsg
                $0.cell.height = { 30 }
                $0.cellStyle = .subtitle
                $0.cell.textLabel?.textColor = .red
                $0.cell.detailTextLabel?.textColor = .red
            }
            if let currentRowIndex = self.indexPath?.row {
                section?.insert(labelRow, at: currentRowIndex + index + 1)
            }
        }
    }
}

extension BaseRow {
    func selectScrolling(animated: Bool = false) {
        guard let indexPath = indexPath, let tableView = baseCell?.formViewController()?.tableView ?? (section?.form?.delegate as? FormViewController)?.tableView  else { return }
        tableView.selectRow(at: indexPath, animated: animated, scrollPosition: .top)
    }
}

extension Eureka.Form {

    public func validateRows(includeHidden: Bool = false, includeDisabled: Bool = true) -> [BaseRow: [ValidationError]] {
        let rowsWithHiddenFilter = includeHidden ? self.allRows : self.rows
        let rowsWithDisabledFilter = includeDisabled ? rowsWithHiddenFilter : rowsWithHiddenFilter.filter { $0.isDisabled != true }

        return rowsWithDisabledFilter.reduce([BaseRow: [ValidationError]]()) { res, row in
            var res = res
            let errors = row.validate()
            if !errors.isEmpty {
                res[row] = errors
            }
            return res
        }
    }

}

extension ActionFormViewController: TapOutsideTableViewDelegate {
    func tableViewDidTapBelowCells(in tableView: UITableView) {
        tableView.endEditing(true)
    }
}

extension BaseRow: Hashable {

    public func hash(into hasher: inout Hasher) {
        guard let tag = self.tag else { return }
        hasher.combine(tag)
    }
}

extension ValidationError: LocalizedError {
    public var errorDescription: String? { return msg }

    public var failureReason: String? { return nil }

    public var recoverySuggestion: String? { return nil }

    public var helpAnchor: String? { return nil }
}

// MARK: ActionParametersUI

extension ActionFormViewController: ActionParametersUI {

    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        guard let parameters = action.parameters else {
            completionHandler(.failure(.noParameters))
            return
        }
        let viewController: ActionFormViewController = ActionFormViewController(style: .grouped, action, actionUI, context, parameters, completionHandler)

        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        navigationController.show()
    }
}
