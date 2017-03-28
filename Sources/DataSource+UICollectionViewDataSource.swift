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
            if self.cachedSectionNames.isEmpty || indexPath.section >= self.cachedSectionNames.count {
                self.cacheSectionNames(using: keyPath)
            }

            var title: Any?
            if !self.cachedSectionNames.isEmpty && indexPath.section < self.cachedSectionNames.count {
                title = self.cachedSectionNames[indexPath.section]
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

        let result = self.fetchedResultsController.fetchKeyPath(keyPath, ascending: ascending)
        self.cachedSectionNames.append(contentsOf: result)
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
