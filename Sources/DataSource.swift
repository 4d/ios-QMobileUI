//
//  DataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore
import XCGLogger

let logger = XCGLogger(identifier: NSStringFromClass(DataSource.self), includeDefaultDestinations: true)

/// Class to present data to table or collection views
public class DataSource: NSObject {

    public enum ViewType {
        case table, collection
    }

    // MARK: Views

    open var viewType: ViewType

    /// The table view
    weak var tableView: UITableView?
    /// The collection view
    weak var collectionView: UICollectionView?

    /// The controller to fetch data
    open var fetchedResultsController: FetchedResultsController

    /// Default cell identifier for cell reuse.
    internal var cellIdentifier: String

    // MARK: Customization
    /// Allow to configure each table cell with selected record
    open var tableConfigurationBlock: ((_ cell: UITableViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)?
    /// Allow to configure each collection cell with selected record
    open var collectionConfigurationBlock: ((_ cell: UICollectionViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)?

    open weak var delegate: DataSourceDelegate?

    // Dictionary to configurate the animations to be applied by each change type. If not configured `.automatic` will be used.
    open var animations: [FetchedResultsChangeType: UITableViewRowAnimation]?

    // MARK: Init
    /// Initialize data source for a table view.
    public init(tableView: UITableView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        self.tableView = tableView
        self.viewType = .table
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName

        super.init()

        self.tableView?.dataSource = self

        self.fetchedResultsController.delegate = self
        self.performFetch()
    }

    /// Initialize data source for a collection view.
    public init(collectionView: UICollectionView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        self.collectionView = collectionView
        self.viewType = .collection
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName

        super.init()

        self.collectionView?.dataSource = self

        self.collectionView?.register(DataSourceCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier)

        self.fetchedResultsController.delegate = self
        self.performFetch()
    }

    deinit {
        self.tableView?.dataSource = nil
        self.collectionView?.dataSource = nil
        self.fetchedResultsController.delegate = nil
    }

    // CLEAN: do two convenience init and one private

    // Cache for collection view
    internal lazy var collectionChanges: CollectionChanges = {
        return CollectionChanges()
    }()

    // MARK: - Variables and shortcut on internal fetchedResultsController

    /// DataSource predicate
    public var predicate: NSPredicate? {
        get {
            return self.fetchedResultsController.fetchRequest.predicate
        }
        set {
            collectionChanges.cachedSectionNames.removeAll()

            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.predicate = newValue

            // CLEAN maybe only if already loaded data one time
            self.refresh()
        }
    }

    /// DataSource sortDescriptors
    public var sortDescriptors: [NSSortDescriptor]? {
        get {
            return self.fetchedResultsController.fetchRequest.sortDescriptors
        }
        set {
            collectionChanges.cachedSectionNames.removeAll()

            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.sortDescriptors = sortDescriptors

            // CLEAN maybe only if already loaded data one time, and do not do it many time
            self.refresh()
        }
    }

    public var sectionNameKeyPath: String? {
        return self.fetchedResultsController.sectionNameKeyPath
    }

    public var count: Int {
        return self.fetchedResultsController.numberOfRecords
    }

    public var numberOfSections: Int {
        return self.fetchedResultsController.numberOfSections
    }

    public func valid(sectionIndex index: Int) -> Bool {
        return index < self.numberOfSections
    }

    public var isEmpty: Bool {
        return self.fetchedResultsController.isEmpty
    }

    public var fetchedRecords: [Record] {
        return self.fetchedResultsController.fetchedRecords ?? [Record]()
    }

    public func record(at indexPath: IndexPath) -> Record? {
        return self.fetchedResultsController.record(at: indexPath)
    }

    public var tableName: String {
        return self.fetchedResultsController.tableName
    }

    // MARK: Cell configuration

    /// Configure a table or collection cell
    func configure(_ cell: UIView, indexPath: IndexPath) {
        if let record = self.record(at: indexPath) {
            if let tableView = self.tableView, let cell = cell as? UITableViewCell {
                cell.tableView = tableView
                if self.delegate?.responds(to: #selector(DataSourceDelegate.dataSource(_:configureTableViewCell:withRecord:atIndexPath:))) != nil {
                    self.delegate?.dataSource?(self, configureTableViewCell: cell, withRecord: record, atIndexPath: indexPath)
                } else if let configuration = self.tableConfigurationBlock {
                    configuration(cell, record, indexPath)
                } else {
                    logger.warning("No cell configuration for \(self)")
                }
            } else if let collectionView = self.collectionView, let cell = cell as? UICollectionViewCell {
                cell.collectionView = collectionView
                if self.delegate?.responds(to: #selector(DataSourceDelegate.dataSource(_:configureCollectionViewCell:withRecord:atIndexPath:))) != nil {
                    self.delegate?.dataSource?(self, configureCollectionViewCell: cell, withRecord: record, atIndexPath: indexPath)
                } else if let configuration = self.collectionConfigurationBlock {
                    configuration(cell, record, indexPath)
                } else {
                    logger.warning("No cell configuration for \(self)")
                }
            }
        }
    }

    /// Reload cells at specific index path
    public func reloadCells(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let tableView = self.tableView {
                if let cell = tableView.cellForRow(at: indexPath) {
                    self.configure(cell, indexPath: indexPath)
                }
            } else if let collectionView = self.collectionView {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    self.configure(cell, indexPath: indexPath)
                }
            }
        }
    }

    // MARK: source functions

    /// Do a fetch
    public func performFetch() {
        do {
            collectionChanges.cachedSectionNames.removeAll()
            try self.fetchedResultsController.performFetch()
        } catch {
            logger.error("Error fetching records \(error)")
        }
    }

    public func refresh() {
        self.performFetch()

        // CLEAN maybe not necessary if fetch notify table to reload
        reloadData()
    }

    func reloadData() {
        switch viewType {
        case .table:
            self.tableView?.reloadData()
        case .collection:
            self.collectionView?.reloadData()
            /*if let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems, !visibleIndexPaths.isEmpty {
             self.collectionView?.reloadItems(at: visibleIndexPaths)
             }*/
        }
    }

}

// MARK: functions about IndexPath
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

        return IndexPath(row: row, section:section)
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

        return IndexPath(row: row, section:section)
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

    public func indexPath(for record: Record) -> IndexPath? {
        return self.fetchedResultsController.indexPath(for: record)
    }

}
