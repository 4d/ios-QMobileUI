//
//  DataSource+UICollectionViewDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

extension DataSource: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.numberOfRecords(in: section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cellIdentifier = self.cellIdentifier

        if let value = self.delegate?.dataSource?(self, cellIdentifierFor: indexPath) {
            cellIdentifier = value
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)

        self.configure(cell, indexPath: indexPath)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let keyPath = self.fetchedResultsController.sectionNameKeyPath {
            if collectionChanges.cachedSectionNames.isEmpty || indexPath.section >= collectionChanges.cachedSectionNames.count {
                self.cacheSectionNames(using: keyPath)
            }

            var title: Any?
            if !collectionChanges.cachedSectionNames.isEmpty && indexPath.section < collectionChanges.cachedSectionNames.count {
                title = collectionChanges.cachedSectionNames[indexPath.section]
            }
            if let view = self.delegate?.dataSource?(self, collectionView: collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath, withTitle: title) {
                return view
            }

            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier, for: indexPath) as? DataSourceCollectionViewHeader {
                headerView.title = title != nil ? String(describing: title!) : ""
                return headerView
            }
        } else if let view = self.delegate?.dataSource?(self, collectionView: collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath, withTitle: nil) {
            return view
        }
        fatalError("Couldn't find view for supplementary element Of kind \(kind) at index \(indexPath). Consider removing the `headerReferenceSize` from your UICollectionViewLayout.")
    }

    func cacheSectionNames(using keyPath: String) {
        var keyPathascending: Bool? = nil

        let sortDescriptorsTmp = self.fetchedResultsController.fetchRequest.sortDescriptors
        guard let sortDescriptors = sortDescriptorsTmp else {
            logger.error("KeyPath \(keyPath) should be included in the fetchRequest's sortDescriptors to know if the keyPath is ascending or descending, but there is not sort descriptors.")
            return
        }

        for sortDescriptor in sortDescriptors where sortDescriptor.key == keyPath {
            keyPathascending = sortDescriptor.ascending
        }
        guard let ascending = keyPathascending else {
            logger.error("KeyPath \(keyPath) should be included in the fetchRequest's sortDescriptors \(sortDescriptors) to know if the keyPath is ascending or descending.")
            return
        }

        let result = self.fetchedResultsController.fetch(keyPath: keyPath, ascending: ascending)
        collectionChanges.cachedSectionNames.append(contentsOf: result)
    }

}

// MARK: - UICollectionViewDatasourcePrefetching
extension DataSource: UICollectionViewDataSourcePrefetching {

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print(indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print(indexPath)
        }
    }

}

// MARK: UICollectionView - update using a list of changes
// struct to manage collection cell updates
struct CollectionChanges {
    internal var objectChanges: [FetchedResultsChangeType: Set<IndexPath>] = [FetchedResultsChangeType: Set<IndexPath>]()
    internal var sectionChanges: [FetchedResultsChangeType: IndexSet] = [FetchedResultsChangeType: IndexSet]()
    internal var cachedSectionNames: [Any] = [Any]()

    mutating func beginUpdates() {
        self.sectionChanges = [FetchedResultsChangeType: IndexSet]()
        self.objectChanges = [FetchedResultsChangeType: Set<IndexPath>]()
    }

    mutating func endUpdates(collectionView: UICollectionView) {
        // Check moves
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

        collectionView.update(with: self)
    }
}

extension UICollectionView {

    func update(with change: CollectionChanges, completion: ((Bool) -> Swift.Void)? = nil) {
        self.performBatchUpdates({
            if let deletedSections = change.sectionChanges[.delete] {
                self.deleteSections(deletedSections as IndexSet)
            }

            if let insertedSections = change.sectionChanges[.insert] {
                self.insertSections(insertedSections as IndexSet)
            }

            if let deleteItems = change.objectChanges[.delete] {
                self.deleteItems(at: Array(deleteItems))
            }

            if let insertedItems = change.objectChanges[.insert] {
                self.insertItems(at: Array(insertedItems))
            }

            if let reloadItems = change.objectChanges[.update] {
                self.reloadItems(at: Array(reloadItems))
            }
            if let moveItems = change.objectChanges[.move] {
                var generator = moveItems.makeIterator()
                guard let fromIndexPath = generator.next() else {
                    assertionFailure("fromIndexPath not found. Move items: \(moveItems)")
                    return
                }
                guard let toIndexPath = generator.next() else {
                    assertionFailure("toIndexPath not found. Move items: \(moveItems)")
                    return
                }
                self.moveItem(at: fromIndexPath as IndexPath, to: toIndexPath as IndexPath)
            }
        }, completion: completion)

    }
}
