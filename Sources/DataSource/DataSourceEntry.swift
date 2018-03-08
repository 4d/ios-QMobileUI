//
//  DataSourceEntry.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

protocol IndexPathObserver {

    func willChangeIndexPath(from: IndexPath?, to: IndexPath?)
    func didChangeIndexPath(from: IndexPath?, to: IndexPath?)

}

/// Object which represent the table and an optional record index
public class DataSourceEntry: NSObject {

    open var dataSource: DataSource
    var indexPathObserver: IndexPathObserver?
    open var indexPath: IndexPath? {
        willSet {
            indexPathObserver?.willChangeIndexPath(from: indexPath, to: newValue)
        }
        didSet {
            indexPathObserver?.didChangeIndexPath(from: oldValue, to: indexPath)
            recordCache = nil
        }
    }
    private var recordCache: BindedRecord?

    @objc dynamic open var record: BindedRecord? {
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
    @objc dynamic open var name: String {
        return self.dataSource.tableName
    }

    @objc dynamic open var count: Int {
        return self.dataSource.count
    }

    @objc dynamic open var countString: String {
        return String(self.count)
    }

    @objc dynamic open var isEmpty: Bool {
        return self.dataSource.isEmpty
    }

    @objc dynamic open var isNotEmpty: Bool {
        return !self.dataSource.isEmpty
    }

    @objc dynamic open var section: Int {
        return self.indexPath?.section ?? 0
    }

    @objc dynamic open var row: Int {
        return self.indexPath?.row ?? 0
    }

    @objc dynamic open var rowString: String {
        return String(self.row)
    }

    @objc dynamic open var hasNext: Bool {
        if let indexPath = self.indexPath {
            return self.dataSource.hasNext(at: indexPath)
        }
        return false
    }

    @objc dynamic open var hasPrevious: Bool {
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

    // MARK: KVO for computed properties
    public override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)

        if key == "hasNext" || key == "hasPrevious" || key == "row" || key == "rowString" || key == "section" {
            keyPaths.insert("indexPath")
        } else if key == "count" || key == "hasPrevious" || key == "isEmpty"  || key == "isNotEmpty" || key == "name" {
            keyPaths.insert("dataSource")
        }

        return keyPaths
    }

}
