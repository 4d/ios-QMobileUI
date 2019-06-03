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
    // forms
    static let alertIfOneField = true // use an alert if one field

    // ui
    static let oneSection = false // Use one section (if false one section by fields)
    static let tableViewStyle: UITableView.Style = .grouped

    // text area
    static let sectionForTextArea = true
    static let textAreaExpand = true // when focus

    // errors
    static let errorColor: UIColor = UIColor(named: "error") ?? .red
    static let errorColorInLabel = true
    static let errorAsDetail = true // use detail label, else add a new row
}

class ActionFormViewController: FormViewController {

    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = UIView()
    var completionHandler: CompletionHandler = { result in }
    var parameters: [ActionParameter] = []

    // ui
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

    // MARK: table

    /*override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     return super.tableView(tableView, heightForHeaderInSection: section)
     }*/
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // colorize header if errors
        if !ActionFormSettings.oneSection && ActionFormSettings.errorColorInLabel && hasValidate {

            if let view = view as? UITableViewHeaderFooterView {
                let rowIndex = section / 2
                guard let row = self.form.allRows[safe: rowIndex] else { return }
                if !row.validationErrors.isEmpty {
                    view.textLabel?.textColor = ActionFormSettings.errorColor
                    if ActionFormSettings.errorAsDetail {
                        view.detailTextLabel?.textColor = ActionFormSettings.errorColor
                    }
                } else {
                    // print("\(rowIndex)-\(String(describing: view.textLabel?.text)): ok")
                    if let noErrorSectionColor = noErrorSectionColor {
                        view.textLabel?.textColor = noErrorSectionColor
                    } else {
                        noErrorSectionColor = view.textLabel?.textColor
                    }
                }
                //view.detailTextLabel?.text = row.validationErrors.first?.msg
            }
        }
    }

    var hasValidate: Bool = false // has validate one time
    var noErrorSectionColor: UIColor? // cache default color of header to reset it

    // MARK: Life

    override func viewDidLoad() {
        tableView = TapOutsideTableView(frame: view.bounds, style: tableViewStyle)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.cellLayoutMarginsFollowReadableWidth = false

        super.viewDidLoad()

        // if plain style remove useless row
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
        hasValidate = true
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
                let animated = true
                if ActionFormSettings.oneSection {
                    row.selectScrolling(animated: animated)
                    row.baseCell.cellBecomeFirstResponder(withDirection: .down)
                } else {
                    // one section by field, scroll to section
                    //row.selectScrolling(animated: animated)
                    row.section?.selectScrolling(animated: animated)
                    row.baseCell.cellBecomeFirstResponder(withDirection: .down)
                }
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
                    cell.textLabel?.textColor = ActionFormSettings.errorColor
                    cell.borderColor = ActionFormSettings.errorColor
                } else {
                    cell.borderColor = ActionFormSettings.errorColor
                }
                if ActionFormSettings.errorAsDetail {
                    if ActionFormSettings.oneSection { // deactivate for the moment, try to display in section
                        cell.detailTextLabel?.text = error.msg
                        cell.detailTextLabel?.textColor = ActionFormSettings.errorColor
                    }
                } else {
                    addValidationErrorRows()
                }

                if ActionFormSettings.errorColorInLabel && !ActionFormSettings.oneSection {
                   self.baseCell?.formViewController()?.tableView?.reloadData()
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
                $0.cell.height = { 15 }
                $0.cellStyle = .subtitle
            }.cellUpdate { cell, _ in
                cell.textLabel?.textColor = .red
                cell.detailTextLabel?.textColor = .red
                cell.backgroundColor = .clear
                cell.borderColor = .clear
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

extension Section {
    func selectScrolling(animated: Bool = false) {
        guard let index = index, let tableView = (self.form?.delegate as? FormViewController)?.tableView  else { return }
        //tableView.scrollToRow(at: IndexPath(row: 0/*NSNotFound*/, section: index), at: .top, animated: animated)

        // implement to scroll if not visible only
        let sectionRect: CGRect = tableView.rect(forSection: index)
        //sectionRect.size.height = tableView.frame.size.height
        tableView.scrollRectToVisible(sectionRect, animated: animated)
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
        let viewController: ActionFormViewController = ActionFormViewController(style: ActionFormSettings.tableViewStyle, action, actionUI, context, parameters, completionHandler)

        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        navigationController.show()
    }
}
