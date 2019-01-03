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

/// Class to present data to table or collection views
public class DataSource: NSObject {

    // MARK: - Views
    public enum ViewType {
        case table, collection
    }

    open var viewType: ViewType

    /// The table view
    weak var tableView: UITableView?
    /// The collection view
    weak var collectionView: UICollectionView?

    // MARK: - data
    /// The controller to fetch data
    open var fetchedResultsController: FetchedResultsController

    /// Default cell identifier for cell reuse.
    open /*private(set)*/ var cellIdentifier: String

    // Cache for collection view
    internal lazy var collectionChanges: CollectionChanges = {
        return CollectionChanges()
    }()

    // MARK: - Customization
    /// Allow to configure each table cell with selected record
    open var tableConfigurationBlock: ((_ cell: UITableViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)? {
        willSet {
            assert(self.viewType == .table)
        }
    }

    /// Allow to configure each collection cell with selected record
    open var collectionConfigurationBlock: ((_ cell: UICollectionViewCell, _ record: Record, _ indexPath: IndexPath) -> Void)? {
        willSet {
            assert(self.viewType == .collection)
        }
    }

    open weak var delegate: DataSourceDelegate?
    open var showSectionBar: Bool = false

    // Dictionary to configurate the animations to be applied by each change type. If not configured `.automatic` will be used.
    open var animations: [FetchedResultsChangeType: UITableView.RowAnimation]?

    // MARK: - Init
    /// Initialize data source for a table view.
    public init(tableView: UITableView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        self.tableView = tableView
        self.viewType = .table
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName

        super.init()

        self.tableView?.dataSource = self

        self.fetchedResultsController.delegate = self
    }

    /// Initialize data source for a collection view.
    public init(collectionView: UICollectionView, fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
        self.collectionView = collectionView
        self.viewType = .collection
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName

        super.init()

        self.collectionView?.dataSource = self

        self.collectionView?.register(DataSourceCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier)

        self.fetchedResultsController.delegate = self
    }

    deinit {
        self.tableView?.dataSource = nil
        self.collectionView?.dataSource = nil
        self.fetchedResultsController.delegate = nil
    }

    // MARK: - Variables and shortcut on internal fetchedResultsController

    /// DataSource predicate
    public var predicate: NSPredicate? {
        get {
            return self.fetchedResultsController.fetchRequest.predicate
        }
        set {
            clearSectionNamesCache()

            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.predicate = newValue

            self.refresh()
        }
    }

    /// DataSource sortDescriptors
    public var sortDescriptors: [NSSortDescriptor]? {
        get {
            return self.fetchedResultsController.fetchRequest.sortDescriptors
        }
        set {
            clearSectionNamesCache()

            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.sortDescriptors = sortDescriptors

            self.refresh()
        }
    }

    public func clearSectionNamesCache() {
        collectionChanges.cachedSectionNames.removeAll()
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

    // MARK: - Cell configuration

    /// Configure a table cell
    func configure(_ cell: UITableViewCell, _ tableView: UITableView, _ indexPath: IndexPath) {
        cell.tableView = tableView
        if let record = self.record(at: indexPath) {
            if self.delegate?.responds(to: #selector(DataSourceDelegate.dataSource(_:configureTableViewCell:withRecord:atIndexPath:))) == true {
                self.delegate?.dataSource?(self, configureTableViewCell: cell, withRecord: record, atIndexPath: indexPath)
            } else if let configuration = self.tableConfigurationBlock {
                configuration(cell, record, indexPath)
            } else {
                logger.warning("No cell configuration for \(self)")
            }
        } else {
            logger.verbose("No record at index \(indexPath) for \(self)")
        }
    }

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

    /*fileprivate func configure(_ cell: UIView, indexPath: IndexPath) {
        if let tableView = self.tableView, let cell = cell as? UITableViewCell {
            configure(cell, tableView, indexPath)
        } else if let collectionView = self.collectionView, let cell = cell as? UICollectionViewCell {
            configure(cell, collectionView, indexPath)
        }
    }*/

    /// Reload cells at specific index path
    public func reloadCells(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let tableView = self.tableView {
                if let cell = tableView.cellForRow(at: indexPath) {
                    self.configure(cell, tableView, indexPath)
                }
            } else if let collectionView = self.collectionView {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    self.configure(cell, collectionView, indexPath)
                }
            }
        }
    }

    // MARK: source functions

    /// Do a fetch
    public func performFetch() {
        do {
            clearSectionNamesCache()
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

extension DataSource {
    public override var description: String {
        return "DataSource[on: \(self.viewType), fetch: \(fetchedResultsController)]"
    }
}
