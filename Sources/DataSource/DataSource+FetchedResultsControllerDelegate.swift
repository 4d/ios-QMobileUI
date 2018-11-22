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
        if let tableView = self.tableView {
            sectionChange(in: tableView, for: type, at: sectionIndex)
        } else if let collectionView = self.collectionView {
            sectionChange(in: collectionView, for: type, at: sectionIndex)
        } else {
            assertionFailure("no view")
        }
    }

    public func controller(_ controller: FetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.delegate?.dataSource?(self, sectionIndexTitleForSectionName: sectionName)
    }

}

// MARK: - utilities
extension DataSource {

    /// Notify view of update beginning.
    fileprivate func beginUpdates() {
        if let tableView = self.tableView {
            tableView.beginUpdates()
        } else if case .collection = self.viewType {
            collectionChanges.beginUpdates()
        } else {
            assertionFailure("no view")
        }
    }

    /// Notify view of update ends.
    fileprivate func endUpdates() {
        if let tableView = self.tableView {
            tableView.endUpdates()
        } else if let collectionView = self.collectionView {
            collectionChanges.endUpdates(collectionView: collectionView)
        }
    }

    /// Notify view about change.
    fileprivate func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        if let tableView = self.tableView {
            didChangeRecord(record, in: tableView, at: indexPath, for: type, newIndexPath)
        } else if let collectionView = self.collectionView {
            didChangeRecord(record, in: collectionView, at: indexPath, for: type, newIndexPath)
        }
    }

    /// notify change immediately to table
    fileprivate func didChangeRecord(_ record: Record, in tableView: UITableView, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        let rowAnimationType = self.animations?[type] ?? .automatic
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
                if tableView.indexPathsForVisibleRows?.index(of: indexPath) != nil {
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

    /// collection change for collection view
    fileprivate func didChangeRecord(_ record: Record, in collectionView: UICollectionView, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        var changeSet = collectionChanges.objectChanges[type] ?? Set<IndexPath>()

        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                changeSet.insert(newIndexPath)
                collectionChanges.objectChanges[type] = changeSet
            }
        case .delete, .update:
            if let indexPath = indexPath {
                changeSet.insert(indexPath)
                collectionChanges.objectChanges[type] = changeSet
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                if indexPath == newIndexPath {
                    changeSet.insert(indexPath)
                    collectionChanges.objectChanges[.update] = changeSet
                } else {
                    changeSet.insert(indexPath)
                    changeSet.insert(newIndexPath)
                    collectionChanges.objectChanges[type] = changeSet
                }
            }
        }
    }

    // MARK: section

    fileprivate func sectionChange(in tableView: UITableView, for type: FetchedResultsChangeType, at sectionIndex: Int) {
        let rowAnimationType = self.animations?[type] ?? .automatic
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        case .move, .update:
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
        }
    }

    fileprivate func sectionChange(in collectionView: UICollectionView, for type: FetchedResultsChangeType, at sectionIndex: Int) {
        clearSectionNamesCache()
        switch type {
        case .insert, .delete:
            if var indexSet = collectionChanges.sectionChanges[type] {
                indexSet.insert(sectionIndex)
                collectionChanges.sectionChanges[type] = indexSet
            } else {
                collectionChanges.sectionChanges[type] = IndexSet(integer: sectionIndex)
            }
        case .move, .update:
            break
        }
    }

}
