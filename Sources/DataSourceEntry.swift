//
//  DataSourceEntry.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Object which represent the table and an optional record index
public class DataSourceEntry: NSObject {

    open var dataSource: DataSource
    open var indexPath: IndexPath? {
        didSet {
            recordCache = nil
        }
    }
    private var recordCache: BindedRecord?

    dynamic open var record: BindedRecord? {
        if recordCache == nil { // init at demand
            if let indexPath = self.indexPath {
                recordCache = dataSource.record(at: indexPath)
            }
        }
        return recordCache
    }

    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }

    // MARK: accessible property

    /// - return: the table name
    dynamic open var name: String {
        return self.dataSource.tableName
    }

    dynamic open var count: Int {
        return self.dataSource.count
    }

    dynamic open var isEmpty: Bool {
        return self.dataSource.isEmpty
    }

    dynamic open var isNotEmpty: Bool {
        return !self.dataSource.isEmpty
    }

    dynamic open var section: Int {
        return self.indexPath?.section ?? 0
    }

    dynamic open var row: Int {
        return self.indexPath?.row ?? 0
    }

    dynamic open var rowString: String {
        return String(self.row)
    }

    dynamic open var hasNext: Bool {
        if let indexPath = self.indexPath {
            return self.dataSource.hasNext(at: indexPath)
        }
        return false
    }

    dynamic open var hasPrevious: Bool {
        if let indexPath = self.indexPath {
            return self.dataSource.hasPrevious(at: indexPath)
        }
        return false
    }

    open var nextIndexPath: IndexPath? {
        if let indexPath = self.indexPath {
            return self.dataSource.nextIndexPath(for: indexPath)
        }
        return nil
    }

    open var previousIndexPath: IndexPath? {
        if let indexPath = self.indexPath {
            return self.dataSource.previousIndexPath(for: indexPath)
        }
        return nil
    }

    open var lastIndexPath: IndexPath? {
        return self.dataSource.lastIndexPath
    }

}
