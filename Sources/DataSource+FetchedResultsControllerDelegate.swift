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
            self.sectionChanges = [FetchedResultsChangeType: IndexSet]()
            self.objectChanges = [FetchedResultsChangeType: Set<IndexPath>]()
        } else {
            assertionFailure("no view")
        }
    }

    public func controllerDidChangeSection(_ controller: FetchedResultsController, at sectionIndex: Int, for type: FetchedResultsChangeType) {
        self.cachedSectionNames.removeAll()

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
            switch type {
            case .insert, .delete:
                if var indexSet = self.sectionChanges[type] {
                    indexSet.insert(sectionIndex)
                    self.sectionChanges[type] = indexSet
                } else {
                    self.sectionChanges[type] = IndexSet(integer: sectionIndex)
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
            var changeSet = self.objectChanges[type] ?? Set<IndexPath>()

            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    changeSet.insert(newIndexPath)
                    self.objectChanges[type] = changeSet
                }
            case .delete, .update:
                if let indexPath = indexPath {
                    changeSet.insert(indexPath)
                    self.objectChanges[type] = changeSet
                }
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    if indexPath == newIndexPath {
                        changeSet.insert(indexPath)
                        self.objectChanges[.update] = changeSet
                    } else {
                        changeSet.insert(indexPath)
                        changeSet.insert(newIndexPath)
                        self.objectChanges[type] = changeSet
                    }
                }
            }
        }
    }

    public func controllerDidChangeContent(_ controller: FetchedResultsController) {
        if let tableView = self.tableView {
            tableView.endUpdates()
        } else if let collectionView = self.collectionView {
            if let moves = self.objectChanges[.move], !moves.isEmpty {
                var updatedMoves = Set<IndexPath>()
                if let insertSections = self.sectionChanges[.insert], let deleteSections = self.sectionChanges[.delete] {
                    var generator = moves.makeIterator()
                    guard let fromIndexPath = generator.next() else {
                        assertionFailure("fromIndexPath not found. Moves: \(moves), inserted sections: \(insertSections), deleted sections: \(deleteSections)")
                        return
                    }
                    guard let toIndexPath = generator.next() else {
                        assertionFailure("toIndexPath not found. Moves: \(moves), inserted sections: \(insertSections), deleted sections: \(deleteSections)")
                        return
                    }
                    if deleteSections.contains((fromIndexPath as NSIndexPath).section) {
                        if insertSections.contains((toIndexPath as NSIndexPath).section) == false {
                            if var changeSet = self.objectChanges[.insert] {
                                changeSet.insert(toIndexPath)
                                self.objectChanges[.insert] = changeSet
                            } else {
                                self.objectChanges[.insert] = [toIndexPath]
                            }
                        }
                    } else if insertSections.contains((toIndexPath as NSIndexPath).section) {
                        if var changeSet = self.objectChanges[.delete] {
                            changeSet.insert(fromIndexPath)
                            self.objectChanges[.delete] = changeSet
                        } else {
                            self.objectChanges[.delete] = [fromIndexPath]
                        }
                    } else {
                        for move in moves {
                            updatedMoves.insert(move as IndexPath)
                        }
                    }
                }
                if !updatedMoves.isEmpty {
                    self.objectChanges[.move] = updatedMoves
                } else {
                    self.objectChanges.removeValue(forKey: .move)
                }
            }
            collectionView.performBatchUpdates({
                if let deletedSections = self.sectionChanges[.delete] {
                    collectionView.deleteSections(deletedSections as IndexSet)
                }

                if let insertedSections = self.sectionChanges[.insert] {
                    collectionView.insertSections(insertedSections as IndexSet)
                }

                if let deleteItems = self.objectChanges[.delete] {
                    collectionView.deleteItems(at: Array(deleteItems))
                }

                if let insertedItems = self.objectChanges[.insert] {
                    collectionView.insertItems(at: Array(insertedItems))
                }

                if let reloadItems = self.objectChanges[.update] {
                    collectionView.reloadItems(at: Array(reloadItems))
                }
                if let moveItems = self.objectChanges[.move] {
                    var generator = moveItems.makeIterator()
                    guard let fromIndexPath = generator.next() else {
                        assertionFailure("fromIndexPath not found. Move items: \(moveItems)")
                        return
                    }
                    guard let toIndexPath = generator.next() else {
                        assertionFailure("toIndexPath not found. Move items: \(moveItems)")
                        return
                    }
                    collectionView.moveItem(at: fromIndexPath as IndexPath, to: toIndexPath as IndexPath)
                }
            }, completion:  nil)
        }
        self.delegate?.dataSourceDidChangeContent?(self)
    }

    public func controller(_ controller: FetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
          return self.delegate?.dataSource?(self, sectionIndexTitleForSectionName: sectionName)
    }

}
