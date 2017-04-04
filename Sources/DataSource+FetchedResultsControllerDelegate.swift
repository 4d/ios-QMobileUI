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

    public func controllerWillChangeContent(_ controller: FetchedResultsController) {
        self.delegate?.dataSourceWillChangeContent?(self)
        if let tableView = self.tableView {
            tableView.beginUpdates()
        } else if case .collection = self.viewType {
            collectionChanges.beginUpdates()
        } else {
            assertionFailure("no view")
        }
    }

    public func controllerDidChangeSection(_ controller: FetchedResultsController, at sectionIndex: Int, for type: FetchedResultsChangeType) {
        if let tableView = self.tableView {
            let rowAnimationType = self.animations?[type] ?? .automatic
            switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
            case .move, .update:
                tableView.reloadSections(IndexSet(integer: sectionIndex), with: rowAnimationType)
            }
        } else if case .collection = self.viewType {
            collectionChanges.cachedSectionNames.removeAll()
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
        } else {
            assertionFailure("no view")
        }
    }

    public func controller(_ controller: FetchedResultsController, didChangeRecord record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let tableView = self.tableView {
            let rowAnimationType = self.animations?[type] ?? .automatic
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: rowAnimationType)
                    self.delegate?.dataSource?(self, didInsertRecord: record, atIndexPath: newIndexPath)
                }
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: rowAnimationType)
                    self.delegate?.dataSource?(self, didDeleteRecord: record, atIndexPath: indexPath)
                }
            case .update:
                if let indexPath = indexPath {
                    if tableView.indexPathsForVisibleRows?.index(of: indexPath) != nil {
                        if let cell = tableView.cellForRow(at: indexPath) {
                            self.configure(cell, indexPath: indexPath)
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
        } else if case .collection = self.viewType {
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
    }

    public func controllerDidChangeContent(_ controller: FetchedResultsController) {
        if let tableView = self.tableView {
            tableView.endUpdates()
        } else if let collectionView = self.collectionView {
            collectionChanges.endUpdates(collectionView: collectionView)
        }
        self.delegate?.dataSourceDidChangeContent?(self)
    }

    public func controller(_ controller: FetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
          return self.delegate?.dataSource?(self, sectionIndexTitleForSectionName: sectionName)
    }

}
