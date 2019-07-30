//
//  ListForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

public protocol ListForm: DataSourceDelegate, DataSourceSortable, ActionContextProvider, Form {

    var tableName: String { get }
    var dataSource: DataSource? { get }
    var predicate: NSPredicate? { get set }
}

let searchController = UISearchController(searchResultsController: nil)
extension ListForm {

    func configureListFormView(_ view: UIView, _ record: AnyObject, _ indexPath: IndexPath) {
        // Give view information about records, let binding fill the UI components
        let entry = self.dataSource?.entry()
        entry?.indexPath = indexPath
        view.table = entry
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
        return dataSource?.record(at: IndexPath.firstRow)
    }

    public var lastRecord: Record? {
        guard let index = dataSource?.lastIndexPath else {
            return nil
        }
        return dataSource?.record(at: index)
    }

}

// MARK: - ActionContextProvider

extension ListForm {

    public func actionContext() -> ActionContext? {
        return self.dataSource
    }

}

extension ListForm where Self: UIViewController {
    func fixNavigationBarColorFromAsset() {
        guard let navigationBar = self.navigationController?.navigationBar else {
            return }
        guard let namedColor = UIColor(named: "ForegroundColor") else { return } // cannot fix
        var attributes = navigationBar.titleTextAttributes ?? [:]
        if let oldColor = attributes[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {

            /// Apple issue with navigation bar color which use asset color as foreground color
            /// If we detect the issue ie. alpha color less than 0.5, we apply your "ForegroundColor" color
            attributes[.foregroundColor] = namedColor
            navigationBar.titleTextAttributes = attributes
        }
        if navigationBar.largeTitleTextAttributes == nil {
            navigationBar.largeTitleTextAttributes = navigationBar.titleTextAttributes
        } else  {
            if navigationBar.largeTitleTextAttributes?[.foregroundColor] == nil {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            } else if let oldColor = navigationBar.largeTitleTextAttributes?[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            }
        }
    }
}
