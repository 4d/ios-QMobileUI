//
//  DataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import QMobileDataStore
import XCGLogger

/// Class to present data to table or collection views
open class DataSource: NSObject {

    // MARK: - data
    /// The controller to fetch data
    open var fetchedResultsController: FetchedResultsController

    /// Default cell identifier for cell reuse.
    open /*private(set)*/ var cellIdentifier: String

    open weak var delegate: DataSourceDelegate?
    open var showSectionBar: Bool = false
    open var sectionFieldFormatter: String?

    /// Initialize data source for a collection view.
    public init(fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
       // self.viewType = viewType
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName
        super.init()

        self.fetchedResultsController.delegate = self
    }

    deinit {
        self.fetchedResultsController.delegate = nil
    }

    // MARK: - Variables and shortcut on internal fetchedResultsController

    /// DataSource predicate
    open var predicate: NSPredicate? {
        get {
            return self.fetchedResultsController.fetchRequest.predicate
        }
        set {
            var fetchRequest = self.fetchedResultsController.fetchRequest
            let oldPredicate = fetchRequest.predicate
            if let newValue = newValue {
                if let contextPredicate = contextPredicate {
                    fetchRequest.predicate = newValue && contextPredicate
                } else {
                    fetchRequest.predicate = newValue
                }
            } else {
                fetchRequest.predicate = contextPredicate
            }

            if oldPredicate != newValue {
                self.refresh()
            } else {
                onWillFetch()
            }
        }
    }

    open var contextPredicate: NSPredicate? {
        didSet {
           let predicate = self.predicate
           self.predicate = predicate // force create predicate XXX crappy, try to have an other value
        }
    }

    /// DataSource sortDescriptors
    public var sortDescriptors: [NSSortDescriptor]? {
        get {
            return self.fetchedResultsController.fetchRequest.sortDescriptors
        }
        set {
            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.sortDescriptors = newValue

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

    // MARK: source functions

    /// Do a fetch
    public func performFetch() {
        do {
            onWillFetch()
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

    // MARK: to override
    func failOverride(_ function: String = #function) {
        #if DEBUG
        assertionFailure("\(function) not implemented")
        #else
        logger.error("\(function) missing implementation. please advice SDK owner.")
        #endif
    }
    func reloadData() {
       failOverride()
    }
    /// Notify view of update beginning.
    func beginUpdates() {
        failOverride()
    }

    /// Notify view of update ends.
    func endUpdates() {
        failOverride()
    }

    public func sectionChange(at sectionIndex: Int, for type: FetchedResultsChangeType) {
        failOverride()
    }

    public func onWillFetch() {
        failOverride()
    }

    /// Reload cells at specific index path
    public func reloadCells(at indexPaths: [IndexPath]) {
        failOverride()
    }

    /// Notify view about change.
    func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        failOverride()
    }

}
