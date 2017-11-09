//
//  ListFormTable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

@IBDesignable
open class ListFormTable: UITableViewController, ListForm {

    public var dataSource: DataSource! = nil

    @IBInspectable open var selectedSegueIdentifier: String = "showDetail"
    @IBInspectable open var hasRefreshControl: Bool = false
    /// Optional section for table using one field name
    @IBInspectable open var sectionFieldname: String?
    @IBOutlet open var searchBar: UISearchBar!
    @IBInspectable open var searchOperator: String = "contains" // beginwith, endwitch
    @IBInspectable open var searchSensitivity: String = "cd"

    @IBOutlet open var nextButton: UIButton?
    @IBOutlet open var previousButton: UIButton?

    public var searchActive: Bool = false
    @IBInspectable open var searchableField: String = "name"

    @IBInspectable open var showSectionBar: Bool = false {
        didSet {
           dataSource?.showSectionBar =  showSectionBar
        }
    }

    // MARK: override
    final public override func viewDidLoad() {
        super.viewDidLoad()

        let fetchedResultsController = dataStore.fetchedResultsController(tableName: self.tableName, sectionNameKeyPath: self.sectionFieldname)
        dataSource = DataSource(tableView: self.tableView, fetchedResultsController: fetchedResultsController)
        dataSource.showSectionBar = showSectionBar

        dataSource.tableConfigurationBlock = { [weak self] cell, record, index in
            self?.configureListFormView(cell, record, index)

            if index.row == self?.tableView.indexPathsForVisibleRows?.last?.row ?? -1 {
                self?.onOpenLastRow()
            }
        }

        dataSource.delegate = self

       // self.tableView.delegate = self

        self.view.table = DataSourceEntry(dataSource: self.dataSource)

        self.installRefreshControll()
        self.installDataEmptyView()
        self.installSearchBar()
        self.installDataSourcePrefetching()
        self.installBackButton()
        onLoad()
        if isSearchBarMustBeHidden {
            searchBar.isHidden = true
        }

    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onWillDisappear(animated)
    }

    final public override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDidDisappear(animated)
    }

    // MARK: table view delegate
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // super.tableView(tableView, didSelectRowAt: indexPath)
        if let record = dataSource.record(at: indexPath) {
            onClicked(record: record, at: indexPath)
        }
    }

    //var triggerTreshold = 10
    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       // super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

       /* Could load more data if pagination 
         if (self.dataSource.items.count - triggerTreshold) == indexPath.row
            && indexPath.row > triggerTreshold {
            onScrollDown(...)
        }*/
    }

    // MARK: segue

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = self.indexPath(for: sender) {
            let table = DataSourceEntry(dataSource: self.dataSource)
            table.indexPath = indexPath

            if let navigation = segue.destination as? UINavigationController {
                navigation.navigationBar.table = table
                navigation.navigationBar.record = table.record
            }
            let destination = segue.destination.firstController
            destination.view.table = table
            destination.view.record = table.record
        }
    }

    // MARK: Events

    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default does nothing
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

    /// Called before starting a refresh
    open func onRefreshBegin() {}
    /// Called after a refresh
    open func onRefreshEnd() {}

    open func onSearchBegin() {}
    open func onSearchButtonClicked() {}
    open func onSearchCancelButtonClicked() {}

    /// Called after a clicked on a record. 
    /// Will not be call if you override tableView(, didSelectRow) or change tableView delegate.
    open func onClicked(record: Record, at index: IndexPath) {}

    // this function is called when last row displayed. Could do some stuff like loading data...
    func onOpenLastRow() {}

    // MARK: Install components

    /// Intall a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        if hasRefreshControl {
            self.refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        }
    }

    open func installDataEmptyView() {
        //self.tableView.emptyDataSetSource = self
        //self.tableView.emptyDataSetDelegate = self
    }

    /// Install the seach bar if defined using storyboard IBOutlet
    open func installSearchBar() {
        // Install seachbar into navigation bar if any
        if let searchBar = searchBar {
            searchBar.delegate = self
            if searchBar.superview == nil {
                self.navigationItem.titleView = searchBar
            }
        }
    }

    /// Install the back button in navigation bar.
    open func installBackButton() {
        checkBackButton()
    }

    /// little function to remove table footer ie. separator
    open func noFooterView() {
        self.tableView.tableFooterView = UIView()
    }

    // MARK: Utility

    /// The table name for this controller.
    /// By default generated from first word in controller name.
    open var tableName: String {
        return defaultTableName
    }

    /// Find the index of specific table cell
    open func indexPath(for cell: Any?) -> IndexPath? {
        if let cell = cell as? UITableViewCell {
            // return self.tableView?.indexPathForSelectedRow
            return self.tableView?.indexPath(for: cell)
        }
        return nil
    }

    public func scrollToRecord(_ record: Record, at scrollPosition: UITableViewScrollPosition = .top) { // more swift notation: scroll(to record: Record
        if let indexPath = dataSource?.indexPath(for: record) {
            self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }
    }

    public func showDetailForm(_ record: Record, animated: Bool = true, scrollPosition: UITableViewScrollPosition = .middle) {
        if let indexPath = dataSource?.indexPath(for: record) {
            self.tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

    // MARK: IBAction

    @IBAction open func refresh(_ sender: Any?) {
        onRefreshBegin()

        //let dataSync = ApplicationDataStore.castedInstance.dataSync
        // _ = dataSync.sync { _ in
        // self.dataSource.performFetch()
        self.refreshControl?.endRefreshing()
        self.onRefreshEnd()
        //}
    }

    /// Scroll to the top of this list form.
    @IBAction open func scrollToTheTop(_ sender: Any?) {
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }

    /// Scroll to the bottom of this list form.
    @IBAction open func scrollToLastRow(_ sender: Any?) {
        if let indexPath = self.dataSource.lastIndexPath {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    /// Scroll to the new section header.
    @IBAction func nextHeader(_ sender: UIButton) {
        let lastSectionIndex = tableView.numberOfSections
        let firstVisibleIndexPath = self.tableView.indexPathsForVisibleRows?[1]
        if (firstVisibleIndexPath?.section)! < lastSectionIndex - 1 {
            previousButton?.alpha = 1
            nextButton?.alpha = 1
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: (firstVisibleIndexPath?.section)!+1), at: .top, animated: true)
        } else {
            nextButton?.alpha = 0.2

        }
    }

    /// Scroll to the previous record.
    @IBAction func previousItem(_ sender: Any?) {
        let firstVisibleIndexPath = self.tableView.indexPathsForVisibleRows?[1]
        if (firstVisibleIndexPath?.section)! > 0 {
            previousButton?.alpha = 1
            nextButton?.alpha = 1
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: (firstVisibleIndexPath?.section)!-1), at: .top, animated: true)
        } else {
            previousButton?.alpha = 0.2
        }
    }

   /* open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerCellIdentifier = "EntityHeader"
        
        if let value = self.dataSource.delegate?.dataSource?(self.dataSource, headCellIdentifierFor: section) {
            headerCellIdentifier = value
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier)
        
        return cell
    }*/

    @IBAction open func searchBarFirstResponder(_ sender: Any?) {
        self.searchBar?.resignFirstResponder()
    }
    @IBAction open func searchBarEndEditing(_ sender: Any?) {
        self.searchBar?.endEditing(true)
    }
}

public class TableSectionHeader: UITableViewHeaderFooterView {
   // @IBOutlet weak var titleLabel: UILabel!
}

// MARK: DataSourceSearchable
import Kingfisher

extension ListFormTable: UITableViewDataSourcePrefetching {

    open func installDataSourcePrefetching() {
        self.tableView.prefetchDataSource = self

        // get all image urls from records
        // let urls = records.flatMap {  }
        // ImagePrefetcher(urls: urls).start()
    }

    open func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

    }

}

// MARK: ListForm is Searchable
extension ListFormTable: DataSourceSearchable {

    /// Perform a seach when text change
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
        performSearch(searchText)
    }

    /// A search begin. Cancel button is displayed.
    /// You can receive this information by overriding `onSearchBegin`
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        onSearchBegin()

        searchBar.setShowsCancelButton(true, animated: true)
    }

    // Search button is clicked. You can receive this information by overriding `onSearchButtonClicked`
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        onSearchButtonClicked()
    }

    /// Cancel button is clicked, cancel the search.
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: false)
        searchBar.endEditing(true)
        dataSource?.predicate = nil
        dataSource?.performFetch()
        onSearchCancelButtonClicked()
    }

    // Function to do search
    func performSearch(_ searchText: String) {
        // XXX could add other predicate
        if !isSearchBarMustBeHidden {
            if !searchText.isEmpty {
                assert(["contains", "beginwith", "endwitch"].contains(searchOperator.lowercased()))
                assert(self.table?.attributes[searchableField] != nil, // XXX maybe a mapped field, try to map to core data field?
                    "Configured field to search '\(searchableField)' is not in table field.\n Check search identifier list form storyboard for class \(self).\n Table: \(String(unwrappedDescrib: table))" )
                dataSource?.predicate = NSPredicate(format: "\(searchableField) \(searchOperator)[\(searchSensitivity)] %@", searchText)
            } else {
                dataSource?.predicate = nil
            }
            dataSource?.performFetch()
        }
        // XXX API here could load more from network
    }

}
