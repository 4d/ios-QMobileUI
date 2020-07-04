//
//  DataSourceEntry.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Interface for object which could listen to `IndexPath` change.
public protocol IndexPathObserver: NSObjectProtocol {

    func willChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?)
    func didChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?)

}

/// Object which represent the table and an optional record index.
public class DataSourceEntry: NSObject {

    /// The data source which represent a table
    open var dataSource: DataSource

    /// The data source which represent a table
    @objc dynamic open var record: BindedRecord?

    /// The record index.
    @objc dynamic open var indexPath: IndexPath? {
        willSet {
            for indexPathObserver in indexPathObservers {
                indexPathObserver.willChangeIndexPath(from: indexPath, to: newValue)
            }
        }
        didSet {
            record = recordFromSource
            for indexPathObserver in indexPathObservers {
                indexPathObserver.didChangeIndexPath(from: oldValue, to: indexPath)
            }
        }
    }

    private var indexPathObservers: [IndexPathObserver] = []
    func add(indexPathObserver: IndexPathObserver) {
        if !indexPathObservers.contains(where: { $0.isEqual(indexPathObserver) }) {
            indexPathObservers.append(indexPathObserver)
        }
    }

    func remove(indexPathObserver: IndexPathObserver) {
        indexPathObservers = indexPathObservers.filter { !self.isEqual($0) }
    }

    // MARK: init
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }

    // MARK: accessible property

    open var recordFromSource: BindedRecord? {
        guard let indexPath = indexPath else {
            return nil
        }
        return dataSource.record(at: indexPath)
    }

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

    // MARK: IndexPath
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
        guard let indexPath = self.indexPath else {
            return false
        }
        return self.dataSource.hasNext(at: indexPath)
    }

    @objc dynamic open var hasPrevious: Bool {
        guard let indexPath = self.indexPath else {
            return false
        }
        return self.dataSource.hasPrevious(at: indexPath)
    }

    open var nextIndexPath: IndexPath? {
        guard let indexPath = self.indexPath else {
            return nil
        }
        return self.dataSource.nextIndexPath(for: indexPath)
    }

    open var previousIndexPath: IndexPath? {
        guard let indexPath = self.indexPath else {
            return nil
        }
        return self.dataSource.previousIndexPath(for: indexPath)
    }

    open var lastIndexPath: IndexPath? {
        return self.dataSource.lastIndexPath
    }

    // MARK: KVO for computed properties
    public override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)

        if key == "hasNext" || key == "hasPrevious"
            || key == "row" || key == "rowString"
            || key == "section"
            || key == "record" {
            keyPaths.insert("indexPath")
        } else if key == "count"
            || key == "hasNext" || key == "hasPrevious"
            || key == "isEmpty"  || key == "isNotEmpty"
            || key == "name" || key == "record" {
            keyPaths.insert("dataSource")
        }

        return keyPaths
    }

}

extension DataSource {
    /// Create a simple entry from this data source.
    func entry() -> DataSourceEntry {
        return DataSourceEntry(dataSource: self)
    }
}

// MARK: UI
import UIKit
public protocol DataSourceEntryUI {

    /// Fill this UI with this entry data
    func prepare(with entry: DataSourceEntry)
}

extension UIViewController: DataSourceEntryUI {
    public func prepare(with entry: DataSourceEntry) {
        if let navigation = self as? UINavigationController {
            navigation.navigationBar.table = entry
        }
        let destination = self.firstController // self or embedded one in nav
        destination.view.table = entry
    }
}
