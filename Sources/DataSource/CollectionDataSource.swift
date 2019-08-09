//
//  CollectionDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

open class CollectionDataSource: DataSource, UICollectionViewDataSource {

    // Dictionary to configurate the animations to be applied by each change type. If not configured `.automatic` will be used.
    open var animations: [FetchedResultsChangeType: UITableView.RowAnimation]?
    open var defaultRowAnimation: UITableView.RowAnimation = .automatic

    /// The collection view
    weak var collectionView: UICollectionView?

    // Cache for collection view
    internal lazy var collectionChanges: CollectionChanges = {
        return CollectionChanges()
    }()

    // MARK: Init

    /// Initialize data source for a collection view.
    public init(collectionView: UICollectionView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        super.init(fetchedResultsController: fetchedResultsController, cellIdentifier: cellIdentifier)
        self.collectionView = collectionView
        self.collectionView?.dataSource = self

        self.collectionView?.register(DataSourceCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier)
    }
    deinit {
        self.collectionView?.dataSource = nil
        self.fetchedResultsController.delegate = nil
    }
    // MARK: sections

    public override func onWillFetch() {
        collectionChanges.cachedSectionNames.removeAll()
    }

    public override func sectionChange(at sectionIndex: Int, for type: FetchedResultsChangeType) {
        if let collectionView = self.collectionView {
            sectionChange(in: collectionView, for: type, at: sectionIndex)
        }
    }
    fileprivate func sectionChange(in collectionView: UICollectionView, for type: FetchedResultsChangeType, at sectionIndex: Int) {
        onWillFetch()
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
    override func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        if let collectionView = self.collectionView {
            didChangeRecord(record, in: collectionView, at: indexPath, for: type, newIndexPath)
        }
    }

    // MARK: - Cell configuration

    /// Configure a collection cell
    func configure(_ cell: UICollectionViewCell, _ collectionView: UICollectionView, _ indexPath: IndexPath) {
        cell.collectionView = collectionView
        if let record = self.record(at: indexPath) {
            if self.delegate?.responds(to: #selector(DataSourceDelegate.dataSource(_:configureCollectionViewCell:withRecord:atIndexPath:))) == true {
                self.delegate?.dataSource?(self, configureCollectionViewCell: cell, withRecord: record, atIndexPath: indexPath)
            } else if let configuration = self.collectionConfigurationBlock {
                configuration(cell, record, indexPath)
            } else {
                logger.warning("No cell configuration for \(self)")
            }
        } else {
            logger.verbose("No record at index \(indexPath) for \(self)")
        }
    }

    /// Allow to configure each collection cell with selected record
    open var collectionConfigurationBlock: ((_ cell: UICollectionViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)? {
        willSet {}
    }
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
        self.configure(cell, collectionView, indexPath)
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
            if let sectionFieldValueFormatter = sectionFieldValueFormatter {
                title = sectionFieldValueFormatter.transformedValue(title)
            }
            if let view = self.delegate?.dataSource?(self, collectionView: collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath, withTitle: title) {
                return view
            }

            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier, for: indexPath) as? DataSourceCollectionViewHeader {
                headerView.title = title != nil ? String(describing: title!) : ""
                return headerView
            }
        } else if let view = self.delegate?.dataSource?(self, collectionView: collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath, withTitle: nil) {
            return view
        }
        fatalError("Couldn't find view for supplementary element Of kind \(kind) at index \(indexPath). Consider removing the `headerReferenceSize` from your UICollectionViewLayout.")
    }

    func cacheSectionNames(using keyPath: String) {
        var keyPathascending: Bool?

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

    // MARK: override

    override func reloadData() {
        self.collectionView?.reloadData()
    }

    public override func reloadCells(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let collectionView = self.collectionView {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    self.configure(cell, collectionView, indexPath)
                }
            }
        }
    }

    /// Notify view of update beginning.
    override func beginUpdates() {
        collectionChanges.beginUpdates()
    }

    /// Notify view of update ends.
    override func endUpdates() {
        if let collectionView = collectionView {
            collectionChanges.endUpdates(collectionView: collectionView)
        }
    }
}

// MARK: - UICollectionViewDatasourcePrefetching
extension CollectionDataSource: UICollectionViewDataSourcePrefetching {

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print(indexPath) // not implemented
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print(indexPath) // not implemented
        }
    }

}

// MARK: - UICollectionView - update using a list of changes
// struct to manage collection cell updates
struct CollectionChanges {
    internal var objectChanges: [FetchedResultsChangeType: Set<IndexPath>] = [FetchedResultsChangeType: Set<IndexPath>]()
    internal var sectionChanges: [FetchedResultsChangeType: IndexSet] = [FetchedResultsChangeType: IndexSet]()
    internal var cachedSectionNames: [Any] = [Any]()
    internal var shouldReloadCollectionView: Bool = false

    mutating func beginUpdates() {
        self.sectionChanges = [FetchedResultsChangeType: IndexSet]()
        self.objectChanges = [FetchedResultsChangeType: Set<IndexPath>]()
        self.shouldReloadCollectionView = false
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
        if shouldReloadCollectionView {
            collectionView.reloadData()
        } else {
            collectionView.update(with: self)
        }
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

extension CollectionDataSource {
    open override var description: String {
        return "TableDataSource[fetch: \(fetchedResultsController)]"
    }
}
