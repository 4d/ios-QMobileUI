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
import BrightFutures

import QMobileAPI

class ActionFormViewController: FormViewController { // swiftlint:disable:this type_body_length 

    var builder: ActionParametersUIBuilder?
    var settings: ActionFormSettings = ActionFormSettings()

    // MARK: Init

    convenience init(builder: ActionParametersUIBuilder, settings: ActionFormSettings = ActionFormSettings()) {
        self.init(style: settings.tableViewStyle)
        self.builder = builder
        self.settings = settings
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func initNavigationBar() {
        let style = self.builder?.action.style
        let styleProperties = style?.properties

        let cancelItem: UIBarButtonItem
        if let dismissLabel = styleProperties?["dismissLabel"] as? String ?? styleProperties?["cancelLabel"] as? String {
            cancelItem = UIBarButtonItem(title: dismissLabel, style: .plain, target: self, action: #selector(cancelAction))
        } else {
            cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))

        }
        self.navigationItem.add(where: .left, item: cancelItem)

        let doneItem: UIBarButtonItem
        if let doneLabel = styleProperties?["doneLabel"] as? String {
            switch doneLabel.lowercased() {
            case "save":
                doneItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(doneAction))
            case "reply":
                doneItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(doneAction))
            default:
                doneItem = UIBarButtonItem(title: doneLabel, style: .done, target: self, action: #selector(doneAction))
            }
        } else {
            doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        }
        self.navigationItem.add(where: .right, item: doneItem)

        self.navigationItem.title = self.builder?.action.preferredShortLabel
        if let navigationBar = self.navigationController?.navigationBar, let tintColor = navigationBar.tintColor {
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: tintColor]
        }
    }

    fileprivate func initDefaultValues() {
        guard let context = self.builder?.context else { return }
        guard let parameters = self.builder?.action.parameters else { return }
        var values: [String: Any?] = [:]
        for parameter in parameters {
            values[parameter.name] = parameter.defaultValue(with: context)
        }
        values = values.compactMapValues { ($0 as? AnyCodable)?.value ?? $0 }
        self.form.setValues(values)
    }

    fileprivate func initRows() {
        guard let parameters = self.builder?.action.parameters else { return }
        if !settings.useSection {
            assertionFailure("No more tested")
            var section = Section()
            self.form.append(section)
            for parameter in parameters {
                let row = parameter.formRow(onRowEvent: self.onRowEvent(cell:row:event:))
                if settings.sectionForTextArea && row is TextAreaRow {
                    // add section to have title for text area (alternatively find a way to display title)
                    section = Section(parameter.preferredLongLabelMandatory)
                    section.append(row)
                    self.form.append(section)
                } else {
                    section.append(row)
                }
            }
        } else {
            for parameter in parameters {
                let section = Section(parameter.preferredLongLabelMandatory)
                let row = parameter.formRow(onRowEvent: self.onRowEvent(cell:row:event:))
                row.title = nil
                section.append(row)
                self.form.append(section)
            }
        }
    }

    // MARK: configure rows

    func onRowEvent(cell: BaseCell?, row: BaseRow, event: RowEvent) {
        // behaviours when selecting element
        if case .onCellHighlightChanged = event {
            // Focus, remove errors
            if !row.isHighlighted, let indexPath = row.indexPath {
                row.remoteErrorsString = []
                let rowIndex = settings.useSection ? indexPath.section: indexPath.row
                self.rowHasBeenEdited.insert(rowIndex)
                self.tableView?.reloadSections([rowIndex], with: .none)
                //self.tableView?.reloadData()
            }

            // Expand text area
            if settings.textAreaExpand, let textAreaRow = row as? TextAreaRow {

                if row.isHighlighted {
                    if case .fixed(let height) = textAreaRow.textAreaHeight {
                        textAreaRow.textAreaHeight = .dynamic(initialTextViewHeight: height)
                        cell?.setup()
                        cell?.layoutIfNeeded()
                        if let indexPath = row.indexPath {
                            cell?.formViewController()?.tableView?.reloadRows(at: [indexPath], with: .none)
                        }
                        (cell as? TextAreaCell)?.textView.becomeFirstResponder()
                    }
                } else {
                    // could not active this code becose reloading row will put row.isHighlighted = false
                    /* if case .dynamic(let height) = textAreaRow.textAreaHeight {
                        textAreaRow.textAreaHeight = .fixed(cellHeight: height)
                        cell?.setup()
                        cell?.layoutIfNeeded()
                        cell?.formViewController()?.tableView?.reloadRows(at: [row.indexPath!], with: .none)
                    }*/
                }
            }
            // if not value set a default one
            if row.baseValue == nil, let row = row as? RowInitializable {
                row.rowInitialize()
            }
            if let updatableRow = row as? DetailHighlightedRow {
                updatableRow.updateHighlighted()
            }
        }
        if case .cellSetup = event {
            if let row = row as? RatingRow {
                row.text = ""
            } else if let row = row as? DateRow {
                row.cell?.datePicker.timeZone = .greenwichMeanTime
            }
        }
    }

    // MARK: table view

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // colorize header if errors
        let rowIndex = section
        if settings.useSection && settings.errorColorInLabel && (hasValidateForm || rowHasBeenEdited.contains(rowIndex)) {
            guard let row = self.form.allRows[safe: rowIndex] else { return nil }
            return row.validationErrors.first?.msg ?? row.remoteErrorsString.first
        }
        return nil
    }

    // MARK: table

    /*override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     return super.tableView(tableView, heightForHeaderInSection: section)
     }*/
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let rowIndex = section
        guard let row = self.form.allRows[safe: rowIndex], settings.useSection && row.hasError else { return 0 }
        return 28
    }

    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        manageErrorOnSectionHeaderFooterView(view, forSection: section)
    }

    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        manageErrorOnSectionHeaderFooterView(view, forSection: section)
    }

    private func manageErrorOnSectionHeaderFooterView(_ view: UITableViewHeaderFooterView, forSection section: Int) {
        let rowIndex = section // XXX mode section
        // colorize footer and add message if errors
        if settings.useSection && settings.errorColorInLabel && (hasValidateForm || rowHasBeenEdited.contains(rowIndex)) {

            guard let row = self.form.allRows[safe: rowIndex] else { return }
            if !row.validationErrors.isEmpty || !row.remoteErrorsString.isEmpty {
                view.textLabel?.textColor = settings.errorColor
                if settings.errorAsDetail {
                    view.detailTextLabel?.textColor = settings.errorColor
                }
            } else {
                if let noErrorSectionColor = noErrorSectionColor {
                    view.textLabel?.textColor = noErrorSectionColor
                } else {
                    noErrorSectionColor = view.textLabel?.textColor
                }
            }
            // view.textLabel?.text = row.validationErrors.first?.msg
            // view.detailTextLabel?.text = row.validationErrors.first?.msg
        }
    }

    var hasValidateForm: Bool = false // has validate one time
    var noErrorSectionColor: UIColor? // cache default color of header to reset it
    var rowHasBeenEdited: Set<Int> = [] // has validate one time

    // MARK: Life

    override func viewDidLoad() {
        tableView = TapOutsideTableView(frame: view.bounds, style: settings.tableViewStyle)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.cellLayoutMarginsFollowReadableWidth = false

        super.viewDidLoad()

        // if plain style remove useless row
        if case .plain = settings.tableViewStyle {
            tableView.tableFooterView = UIView()
        }

        /*if let label = builder?.action.label, let shortLabel = builder?.action.shortLabel, label != shortLabel {
            let headerLabel = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
            headerLabel.text = label
            tableView.tableHeaderView = headerLabel
            headerLabel.sizeToFit()
            //tableView.separatorStyle = .none
        }*/

        initRows()
        initDefaultValues()
        initNavigationBar()

        navigationOptions = [.Enabled, .StopDisabledRow]
        animateScroll = true
        rowKeyboardSpacing = 20 // Leaves 20pt of space between the keyboard and the highlighted row after scrolling to an off screen row
    }

    open override var customNavigationAccessoryView: (UIView & NavigationAccessory)? {
        if let image = UIImage(named: "keyboardDismiss") {
            let accessoryView = NavigationAccessoryView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
            let originalButton = accessoryView.doneButton
            accessoryView.doneButton = UIBarButtonItem(image: image, style: .done, target: originalButton.target, action: originalButton.action)

            // reset all the items
            var items = accessoryView.items ?? []
            items[items.count-1] = accessoryView.doneButton // done is last
            accessoryView.setItems(items, animated: false)
            return accessoryView
        }
        return nil
    }

    // MARK: Actions

    @objc func doneAction(sender: UIButton!) {
        hasValidateForm = true
        remoteRemoteErrors()
        let errors = self.form.validateRows()
        if errors.isEmpty {
            sender.isEnabled = false
            send { _ in
                onForeground {
                    sender.isEnabled = true
                }
            }
        } else {

            // display errors
            if settings.errorColorInLabel && settings.useSection {
                self.refreshToDisplayErrors()
            } else {
                // remove if no more errors
                for row in self.form.rows where row.validationErrors.isEmpty {
                    row.removeValidationErrorRows()
                }
                for (row, rowErrors) in errors {
                    row.display(errors: rowErrors, with: settings)
                }
            }

            // scroll to first row with errors
            let rows = self.form.rows.filter { !$0.validationErrors.isEmpty }
            if let row = rows.first {
                let animated = true
                if !settings.useSection {
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

    /// Get form values.
    func formValues(completionHandler: @escaping (ActionParameters) -> Void) {
        let values = self.form.values()
        /// Remove nil values.
        var parameters = values.reduce(ActionParameters()) { (dict, entry) in
            guard let value = entry.1 else { return dict }
            var dict = dict
            dict[entry.0] = value
            return dict
        }

        let images = parameters.compactMapValues { $0 as? UIImage }
        if images.isEmpty {
            // No image, return immediatly
            completionHandler(parameters)
        } else {
            // upload images
            var itemDone = 0
            for (key, image) in images {
                let imageCompletion: APIManager.CompletionUploadResultHandler = { result in
                    switch result {
                    case .success(let uploadResult):
                        logger.debug("Image uploaded \(uploadResult)")
                        parameters[key] = uploadResult
                    case .failure(let error):
                        logger.warning("Failed to upload image \(error): \(String(describing: error.responseString))") // ok: true is not ok! we need id
                        parameters.removeValue(forKey: key) // Not convertible
                    }
                    itemDone += 1
                    if itemDone == images.count {
                        completionHandler(parameters)
                    }
                }
                if let url = (self.form.rowBy(tag: key) as? ImageRow)?.imageURL {
                    logger.debug("Upload image using url \(url)")
                    _ = APIManager.instance.upload(url: url, completionHandler: imageCompletion)
                } else if let imageData = image.jpegData(compressionQuality: 1) {
                    logger.debug("Upload image using jpegData")
                    _ = APIManager.instance.upload(data: imageData, image: true, mimeType: "image/jpeg", completionHandler: imageCompletion)
                } else if let imageData = image.pngData() {
                    logger.debug("Upload image using pngData")
                    _ = APIManager.instance.upload(data: imageData, image: true, mimeType: "image/png", completionHandler: imageCompletion)
                } else {
                    parameters.removeValue(forKey: key) // Not convertible
                }
            }
        }
    }

    /// Send action to server, and manage result
    func send(completionHandler: @escaping (Result<ActionResult, APIError>) -> Void) {
        formValues { values in
            self.builder?.success(with: values) { result in
                let promise = Promise<ActionResult, APIError>()
                completionHandler(result)
                switch result {
                case .success(let actionResult):
                    if actionResult.success || actionResult.close {
                        onForeground {
                            self.dismiss(animated: true) {
                                logger.debug("Action parameters form dismissed")
                                promise.complete(result)
                            }
                        }
                    } else {
                        if let errors = actionResult.errors {
                            var errorsByComponents: [String: [String]] = [:]
                            for error in errors {
                                if let error = error as? [String: String], let tag = error["component"] ?? error["parameter"], let message = error["message"] {
                                    if errorsByComponents[tag] == nil {
                                        errorsByComponents[tag] = []
                                    }
                                    errorsByComponents[tag]?.append(message)
                                }
                            }

                            for (key, restErrors) in errorsByComponents {
                                if let row = self.form.rowBy(tag: key) {
                                    row.remoteErrorsString = restErrors
                                } else {
                                    logger.warning("Unknown field returned \(key) to display associated errors")
                                }
                            }
                            self.refreshToDisplayErrors()
                        } else {
                            logger.warning("Action result \(actionResult): nothing to do or display. Action form not closed. Send success or close with True value to dismiss it.")
                        }
                        promise.complete(result)
                    }
                case .failure(let error):
                    logger.debug("Errors from 4d server")
                    if let restErrors = error.restErrors {
                        /*if let statusText = restErrors.statusText {

                         }*/

                        let errorsByComponents: [String: [String]] = restErrors.errors.asDictionaryOfArray(transform: { error in
                            return [error.componentSignature: error.message]
                        })

                        for (key, restErrors) in errorsByComponents {
                            if let row = self.form.rowBy(tag: key) {
                                row.remoteErrorsString = restErrors
                            } else {
                                logger.warning("Unknown field returned \(key) to display associated errors")
                            }
                        }
                        self.refreshToDisplayErrors()
                    }
                    promise.complete(result)
                }
                return promise.future
            }
        }
    }

    private func refreshToDisplayErrors() {
        onForeground {
            self.tableView?.reloadData()
        }
    }
    private func remoteRemoteErrors() {
        for row in self.form.allRows {
            row.remoteErrorsString = []
        }
    }

    @objc func cancelAction(sender: Any!) {
        self.dismiss(animated: true) {
            self.builder?.completionHandler(.failure(.userCancel))
        }
    }

}

private var xoAssociationKey: UInt8 = 0
// MARK: extension eureka
extension Eureka.BaseRow {

    // Reset rows validation
    func display(errors: [ValidationError], with settings: ActionFormSettings) {
        if let error = errors.first {
            if let cell = self.baseCell {
                if !settings.useSection {
                    cell.textLabel?.textColor = settings.errorColor
                    cell.borderColor = settings.errorColor
                } else {
                    cell.borderColor = settings.errorColor
                }
                if settings.errorAsDetail {
                    if !settings.useSection { // deactivate for the moment, try to display in section
                        cell.detailTextLabel?.text = error.msg
                        cell.detailTextLabel?.textColor = settings.errorColor
                    }
                } else {
                    addValidationErrorRows()
                }

            }
        }
        // XXX multiple errors?
    }

    @objc dynamic open var remoteErrorsString: [String] {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey) as? [String] ?? []
        } set {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    open var remoteErrors: [ValidationError] {
        return remoteErrorsString.map { ValidationError(msg: $0) }
    }

    fileprivate var hasError: Bool {
        return !self.validationErrors.isEmpty || !self.remoteErrorsString.isEmpty
    }
}

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
        guard let index = index, let controller = self.form?.delegate as? FormViewController, let tableView = controller.tableView  else { return }
        //tableView.scrollToRow(at: IndexPath(row: 0/*NSNotFound*/, section: index), at: .top, animated: animated)

        // implement to scroll if not visible only
        let sectionRect: CGRect = tableView.rect(forSection: index)
        /*if let offset = controller.navigationController?.navigationBar.height {
            sectionRect = sectionRect.with(y: sectionRect.y + offset + 100)
        }*/
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

// MARK: listen to click outside

extension ActionFormViewController: TapOutsideTableViewDelegate {
    func tableViewDidTapBelowCells(in tableView: UITableView) {
        tableView.endEditing(true)
    }
}

// MARK: ActionParametersUI

extension ActionFormViewController: ActionParametersUI {

    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) -> ActionParametersUIControl? {
        if action.parameters == nil {
            completionHandler(.failure(.noParameters))
            return nil
        }
        let viewController: ActionFormViewController = ActionFormViewController(builder: ActionParametersUIBuilder(action, actionUI, context, completionHandler))

        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        return navigationController
    }
}
//swiftlint:disable:this file_length
