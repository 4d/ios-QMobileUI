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

/// Context of a form, to filter or have information on parent controller
public struct FormContext {

    var predicate: NSPredicate?
    var actionContext: ActionContext?

}

/// A List form display a list of table data
public protocol ListForm: DataSourceDelegate, DataSourceSortable, ActionContextProvider, Form {

    var tableName: String { get }
    var dataSource: DataSource? { get }
    var formContext: FormContext? { get set }
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
        } else {
            if navigationBar.largeTitleTextAttributes?[.foregroundColor] == nil {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            } else if let oldColor = navigationBar.largeTitleTextAttributes?[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            }
        }
    }

}

public protocol ListFormSearchable: ListForm/*, DataSourceSearchable*/ {
    var searchBar: UISearchBar! { get set }
    /// Add search bar in place of navigation bar title
    var searchableAsTitle: Bool { get }
    /// Keep search bar if scrolling (only if searchableAsTitle = false)
    var searchableWhenScrolling: Bool { get }
    /// Hide navigation bar when searching (only if searchableAsTitle = false)
    var searchableHideNavigation: Bool { get }

    func onSearchBegin()
    func onSearchButtonClicked()
    func onSearchFetching()
    func onSearchCancel()
}

extension ListFormSearchable where Self: UIViewController {
    func doInstallSearchBar() {
       var searchBar = self.searchBar
        // Install seachbar into navigation bar if any
        if !isSearchBarMustBeHidden {
            if searchBar?.superview == nil {
                if searchableAsTitle {
                    self.navigationItem.titleView = searchBar
                } else {
                    let searchController = UISearchController(searchResultsController: self)
                    searchController.searchResultsUpdater = self
                    searchController.obscuresBackgroundDuringPresentation = false
                    searchController.dimsBackgroundDuringPresentation = false
                    searchController.hidesNavigationBarDuringPresentation = searchableHideNavigation
                    searchController.delegate = self
                    self.navigationItem.searchController = searchController
                    self.navigationItem.hidesSearchBarWhenScrolling = !searchableWhenScrolling
                    self.definesPresentationContext = true

                    searchController.searchBar.copyAppearance(from: self.searchBar)
                    self.searchBar = searchController.searchBar // continue to manage search using listener
                    searchBar = self.searchBar

                    if let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor { // XXX I do not find another way, this not restrict change to this controller...
                        let appearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
                        appearance.defaultTextAttributes = [NSAttributedString.Key.foregroundColor: navigationBarColor]
                    }
                }
            }
        }
        if let subview = searchBar?.subviews.first {
            let textFields = subview.subviews.compactMap({$0 as? UITextField })
            if let searchTextField = textFields.first {
                searchTextField.tintColor = searchTextField.textColor // the |
                if !searchableAsTitle {
                    if let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor {
                        searchTextField.tintColor = navigationBarColor
                    }
                }
            }
        }
        searchBar?.delegate = self

        if isSearchBarMustBeHidden {
            searchBar?.isHidden = true
        }
    }

    func performSearch(_ searchText: String) {
        if !isSearchBarMustBeHidden {
            // Create the search predicate
            dataSource?.predicate = createSearchPredicate(searchText, tableInfo: tableInfo)

            // Event
            onSearchFetching()
        }
        // XXX API here could load more from network
    }

    func do_searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // XXX could add other predicate
        searchBar.showsCancelButton = true
        performSearch(searchText)
    }

    func do_searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        onSearchBegin()
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func do_searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.endEditing(true)
        onSearchButtonClicked()
    }

    func do_searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: false)
        searchBar.endEditing(true)
        dataSource?.predicate = nil
        onSearchCancel()
    }

    func do_updateSearchResults(for searchController: UISearchController) {
        //let searchBar = searchController.searchBar
        //if let searchText = searchBar.text {
        //performSearch(searchText) // already done by search bar listener
        //}
    }
}
