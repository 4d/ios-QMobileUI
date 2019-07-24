//
//  DataSource+FetchedResultsControllerDelegate.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

extension DataSource: FetchedResultsControllerDelegate {

    // MARK: - changes

    public func controllerWillChangeContent(_ controller: FetchedResultsController) {
        logger.debug("Updating data source for table \(fetchedResultsController.tableName) start ")
        self.delegate?.dataSourceWillChangeContent?(self)
        beginUpdates()
    }

    public func controller(_ controller: FetchedResultsController, didChangeRecord record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, newIndexPath: IndexPath?) {
        didChangeRecord(record, at: indexPath, for: type, newIndexPath)
    }

    public func controllerDidChangeContent(_ controller: FetchedResultsController) {
        self.endUpdates()
        self.delegate?.dataSourceDidChangeContent?(self)
        logger.debug("Updating data source for table \(fetchedResultsController.tableName) finish ")
    }

    // MARK: - section

    public func controllerDidChangeSection(_ controller: FetchedResultsController, at sectionIndex: Int, for type: FetchedResultsChangeType) {
        sectionChange(at: sectionIndex, for: type)
    }

    public func controller(_ controller: FetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.delegate?.dataSource?(self, sectionIndexTitleForSectionName: sectionName)
    }

}
