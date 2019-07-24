//
//  TableDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

open class TableDataSource: DataSource, UITableViewDataSource {

    /*
     // try to conform to new diffable data source
    typealias CellProvider = (UITableView, IndexPath, Any) -> UITableViewCell?
    var cellProvider: CellProvider = { tableView, indexPath, value in
        var cellIdentifier = self.cellIdentifier
        if let value = self.delegate?.dataSource?(self, cellIdentifierFor: indexPath) {
            cellIdentifier = value
        }
        assert(tableView.dequeueReusableCell(withIdentifier: cellIdentifier) != nil, "Table view cell not well configured in storyboard to \(cellIdentifier)")

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        self.configure(cell, tableView, indexPath)
        return cell
     }*/

    // Dictionary to configurate the animations to be applied by each change type. If not configured `.automatic` will be used.
    open var animations: [FetchedResultsChangeType: UITableView.RowAnimation]?
    open var defaultRowAnimation: UITableView.RowAnimation = .automatic

    /// The table view
    weak var tableView: UITableView?
    // MARK: - Cell configuration

    /// Configure a table cell
    func configure(_ cell: UITableViewCell, _ tableView: UITableView, _ indexPath: IndexPath) {
        if let record = self.record(at: indexPath) {
            if self.delegate?.responds(to: #selector(DataSourceDelegate.dataSource(_:configureTableViewCell:withRecord:atIndexPath:))) == true {
                self.delegate?.dataSource?(self, configureTableViewCell: cell, withRecord: record, atIndexPath: indexPath)
            } else if let configuration = self.tableConfigurationBlock {
                configuration(cell, record, indexPath)
            } else {
                logger.warning("No cell configuration for \(self)")
            }
        } else {
            logger.verbose("No record at index \(indexPath) for \(self)")
        }
    }

    // MARK: - Init
    /// Initialize data source for a table view.
    public init(tableView: UITableView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        super.init(fetchedResultsController: fetchedResultsController, cellIdentifier: cellIdentifier)
        self.tableView = tableView
        self.tableView?.dataSource = self
    }

    deinit {
        self.tableView?.dataSource = nil
        self.fetchedResultsController.delegate = nil
    }

    // MARK: section

    fileprivate func sectionChange(in tableView: UITableView, for type: FetchedResultsChangeType, at sectionIndex: Int) {
        let rowAnimationType = self.animations?[type] ?? defaultRowAnimation
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        case .move, .update:
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        }
    }

    public override func sectionChange(at sectionIndex: Int, for type: FetchedResultsChangeType) {
        if let tableView = self.tableView {
            sectionChange(in: tableView, for: type, at: sectionIndex)
        }
    }

    // MARK: - Customization
    /// Allow to configure each table cell with selected record
    open var tableConfigurationBlock: ((_ cell: UITableViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)? {
        willSet {}
    }
    /// notify change immediately to table
    fileprivate func didChangeRecord(_ record: Record, in tableView: UITableView, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        let rowAnimationType = self.animations?[type] ?? defaultRowAnimation
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                if indexPath != newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: rowAnimationType)
                    self.delegate?.dataSource?(self, didInsertRecord: record, atIndexPath: newIndexPath)
                } else {
                    logger.warning("Issue when inserting a row, old and new indexes are equal: \(newIndexPath)")
                }
            }
        case .delete:
            if let indexPath = indexPath {
                logger.verbose("Delete record \(record) from data source ")
                tableView.deleteRows(at: [indexPath], with: rowAnimationType)
                self.delegate?.dataSource?(self, didDeleteRecord: record, atIndexPath: indexPath)
            }
        case .update:
            if let indexPath = indexPath {
                if tableView.indexPathsForVisibleRows?.firstIndex(of: indexPath) != nil {
                    if let cell = tableView.cellForRow(at: indexPath) {
                        self.configure(cell, tableView, indexPath)
                    }

                    self.delegate?.dataSource?(self, didUpdateRecord: record, atIndexPath: indexPath)
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: rowAnimationType)
                tableView.insertRows(at: [newIndexPath], with: rowAnimationType)

                self.delegate?.dataSource?(self, didMoveRecord: record, fromIndexPath: indexPath, toIndexPath: newIndexPath)
            }
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.numberOfRecords(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellIdentifier = self.cellIdentifier

        if let value = self.delegate?.dataSource?(self, cellIdentifierFor: indexPath) {
            cellIdentifier = value
        }

        assert(tableView.dequeueReusableCell(withIdentifier: cellIdentifier) != nil, "Table view cell not well configured in storyboard to \(cellIdentifier)")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.tableView = tableView
        self.configure(cell, tableView, indexPath)
        return cell
    }

    // MARK: Sections and Headers

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showSectionBar {
            if let titles = self.delegate?.sectionIndexTitlesForDataSource?(self, tableView: tableView) {
                return titles
            } else if let keyPath = self.fetchedResultsController.sectionNameKeyPath, !keyPath.isEmpty {
                let result = self.fetchedResultsController.fetch(keyPath: keyPath, ascending: true)
                return result.map { "\($0)"}
                // fetchedResultsController.sectionIndexTitles ??
            }
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let index = self.delegate?.dataSource?(self, tableView: tableView, sectionForSectionIndexTitle: title, atIndex: index) {
            return index
        }
        return self.fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let title = self.delegate?.dataSource?(self, tableView: tableView, titleForHeaderInSection: section) {
            return title
        }
        return self.fetchedResultsController.sectionName(section) ?? ""
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.delegate?.dataSource?(self, tableView: tableView, titleForFooterInSection: section)
    }

    // MARK: Editing

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.delegate?.dataSource?(self, tableView: tableView, canEditRowAtIndexPath: indexPath) ?? true
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.delegate?.dataSource?(self, tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }

    // MARK: Moving or Reordering

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return self.delegate?.dataSource?(self, tableView: tableView, canMoveRowAtIndexPath: indexPath) ?? false
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.delegate?.dataSource?(self, tableView: tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }

    // MARK: override

    override func reloadData() {
        self.tableView?.reloadData()
    }

    public override func onWillFetch() {
        // nothing to do
    }

    public override func reloadCells(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let tableView = self.tableView {
                if let cell = tableView.cellForRow(at: indexPath) {
                    self.configure(cell, tableView, indexPath)
                }
            }
        }
    }

    /// Notify view about change.
    override func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        if let tableView = self.tableView {
            didChangeRecord(record, in: tableView, at: indexPath, for: type, newIndexPath)
        }
    }

    /// Notify view of update beginning.
    override func beginUpdates() {
        if let tableView = self.tableView {
            tableView.beginUpdates()
        }
    }

    /// Notify view of update ends.
    override func endUpdates() {
        if let tableView = self.tableView {
            tableView.endUpdates()
        }
    }

}

extension TableDataSource {
    open override var description: String {
        return "TableDataSource[fetch: \(fetchedResultsController)]"
    }
}
