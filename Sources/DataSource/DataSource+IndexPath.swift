//
//  DataSource+IndexPath.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/11/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// Functions about `IndexPath`
extension DataSource {

    public func hasNext(at indexPath: IndexPath) -> Bool {
        let numberOfSections = self.numberOfSections
        if numberOfSections == 0 {
            return false // no section
        }
        if indexPath.section < numberOfSections - 1 {
            return true
        }

        return true
    }

    public func nextIndexPath(for indexPath: IndexPath) -> IndexPath? {
        var row = indexPath.row + 1
        var section = indexPath.section

        if isLastInSection(indexPath: indexPath) {
            if isLastSection(indexPath.section) {
                return nil
            }
            section += 1

            let numberOfObjects = self.fetchedResultsController.numberOfRecords(in: section)
            if numberOfObjects == 0 {
                return nil
            }
            row = 0
        }

        return IndexPath(row: row, section: section)
    }

    public func previousIndexPath(for indexPath: IndexPath) -> IndexPath? {
        var row = indexPath.row - 1
        var section = indexPath.section

        if indexPath.isFirstRowInSection {
            if isFirstSection(section) {
                return nil // No previous if first object
            }

            section -= 1

            let numberOfObjects = self.fetchedResultsController.numberOfRecords(in: section)
            if numberOfObjects == 0 {
                return nil
            }

            row = numberOfObjects - 1
        }

        return IndexPath(row: row, section: section)
    }

    func isFirstSection (_ section: Int) -> Bool {
        return self.previousSection(for: section) == nil
    }

    func isLastSection(_ section: Int) -> Bool {
        return self.nextSection(for: section) == nil
    }

    func nextSection(for section: Int) -> Int? {
        let numberOfSections = self.numberOfSections
        if section >= numberOfSections - 1 {
            return nil
        }
        return section + 1
    }
    func previousSection(for section: Int) -> Int? {
        if section == 0 {
            return nil
        }
        return section - 1
    }

    public func hasPrevious(at indexPath: IndexPath) -> Bool {
        return indexPath.hasPreviousRow // TEST : row or item?
    }

    public func isLastInSection(indexPath: IndexPath) -> Bool {
        let lastItem = self.fetchedResultsController.numberOfRecords(in: indexPath.section)
        return lastItem - 1 == indexPath.row
    }

    public var lastIndexPath: IndexPath? {
        let numberOfSections = self.numberOfSections
        if numberOfSections == 0 {
            return nil
        }
        return lastIndexPath(section: numberOfSections - 1)
    }

    public func lastIndexPath(section: Int) -> IndexPath {
        let lastItem = self.fetchedResultsController.numberOfRecords(in: section)
        if lastItem == NSNotFound {
            return IndexPath(row: NSNotFound, section: section)
        }
        return IndexPath(row: lastItem - 1, section: section)
    }

    /*public func isLastInLine(indexPath: IndexPath) -> Bool {
     let nextIndexPath = indexPath.nextRowInSection

     if let cellAttributes = collectionView.layout.layoutAttributesForItem(at: indexPath), let nextCellAttributes = self.layoutAttributesForItem(at: nextIndexPath) {
     return !(cellAttributes.frame.minY == nextCellAttributes.frame.minY)
     }
     return false
     }*/

    func inBounds(indexPath: IndexPath) -> Bool {
        return self.fetchedResultsController.inBounds(indexPath: indexPath)
    }

}
// MARK: - record
import QMobileDataStore
extension DataSource {

    public func indexPath(for record: Record) -> IndexPath? {
        return self.fetchedResultsController.indexPath(for: record)
    }

}
