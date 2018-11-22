//
//  ListForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

public protocol ListForm: DataSourceDelegate, DataSourceSortable {

    var tableName: String { get }
    var dataSource: DataSource! { get }
}

let searchController = UISearchController(searchResultsController: nil)
extension ListForm {

    func configureListFormView(_ view: UIView, _ record: AnyObject, _ indexPath: IndexPath) {
        // Give view information about records, let binding fill the UI components
        let entry = self.dataSource.entry
        entry.indexPath = indexPath
        view.table = entry
        // view.record = record
    }

    var defaultTableName: String {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)

        let name = className.camelFirst
        if NSClassFromString(name) != nil { // check entity
            return name
        }
        logger.error("Looking for class \(className) to determine the type of records to load. But no class with this name found in the project. Check your data model.")
        abstractMethod(className: className)
    }

    public var firstRecord: Record? {
        return dataSource.record(at: IndexPath.firstRow)
    }

    public var lastRecord: Record? {
        guard let index = dataSource.lastIndexPath else {
            return nil
        }
        return dataSource.record(at: index)
    }

}
