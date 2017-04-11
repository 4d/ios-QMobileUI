//
//  DetailsFormController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

public protocol DetailsForm: class {

    // the root view of form
    var view: UIView! {get}

    /// @return: true if the is previous record
    var hasPreviousRecord: Bool {get set}
    /// @return: true if the is next record
    var hasNextRecord: Bool {get set}

}

extension DetailsForm {

    // MARK: model info from DataSource
    public var dataSource: DataSource? {
        return self.view.table?.dataSource
    }

    public var indexPath: IndexPath? {
        return self.view.table?.indexPath
    }

    public var record: Record? {
        return self.view.record as? Record
    }

    // MARK: standards actions

    public func nextRecord() {
        if let table = self.view.table {
            if let newIndex = table.nextIndexPath {

                table.indexPath = newIndex

                // update the view (if not done auto by seting the index)
                self.view.record = table.record

                checkActions(table)
            }
        }
    }

    public func previousRecord() {

        if let table = self.view.table {
            if let newIndex = table.previousIndexPath {

                table.indexPath = newIndex

                // update the view (if not done auto by seting the index)
                self.view.record = table.record

                checkActions(table)
            }
        }
    }

    public func firstRecord() {
        if let table = self.view.table {
            table.indexPath = IndexPath.firstRow

            // update the view (if not done auto by seting the index)
            self.view.record = table.record

            checkActions(table)
        }
    }

    public func lastRecord() {
        if let table = self.view.table {
            table.indexPath = table.lastIndexPath // check nullity?

            // update the view (if not done auto by seting the index)
            self.view.record = table.record

            checkActions(table)
        }
    }

    func checkActions() {
        if let table = self.view.table {
            checkActions(table)
        } else {
            assertionFailure("No table set when loading")
        }
    }

    func checkActions(_ table: DataSourceEntry) {
        self.hasPreviousRecord = table.hasPrevious
        self.hasNextRecord = table.hasNext
    }

    /*public*/ func deleteRecord() {
        if let table = self.view.table {
            if let record = table.record?.record as? Record {
                _ = dataStore.perform(.background) { context, _ in
                    context.delete(record: record)
                }
            } else {
                logger.warning("Failed to get selected record for deletion")
            }
        }
    }

}
