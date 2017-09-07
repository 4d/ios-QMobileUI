//
//  DataSource+UITableViewDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

extension DataSource: UITableViewDataSource {

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
        self.configure(cell, indexPath: indexPath)
        return cell
    }

    // MARK: Sections and Headers

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showSection {
            if let titles = self.delegate?.sectionIndexTitlesForDataSource?(self, tableView: tableView) {
                return titles
            } else if let keyPath = self.fetchedResultsController.sectionNameKeyPath {
                let result = self.fetchedResultsController.fetch(keyPath: keyPath, ascending: true)
                return result.map { "\($0)"}
            }
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.delegate?.dataSource?(self, tableView: tableView, sectionForSectionIndexTitle: title, atIndex: index) ?? index
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
        return self.delegate?.dataSource?(self, tableView: tableView, canEditRowAtIndexPath: indexPath) ?? false
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        self.delegate?.dataSource?(self, tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }

    // MARK: Moving or Reordering

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return self.delegate?.dataSource?(self, tableView: tableView, canMoveRowAtIndexPath: indexPath) ?? false
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.delegate?.dataSource?(self, tableView: tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }

}
