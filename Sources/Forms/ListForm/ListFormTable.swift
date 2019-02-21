//
//  ListFormTable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

import Moya
import SwiftMessages
import Prephirences

@IBDesignable
open class ListFormTable: UITableViewController, ListForm {

    public var dataSource: DataSource! = nil

    @IBInspectable open var selectedSegueIdentifier: String = "showDetails"

    @IBOutlet open var searchBar: UISearchBar!
    public private(set) var searchActive: Bool = false
    /// Operator used to search. contains, beginwith, endwith. Default contains
    @IBInspectable open var searchOperator: String = "contains" {
        didSet {
            assert(["contains", "beginwith", "endwitch"].contains(searchOperator.lowercased()))
        }
    }
        /// Case sensitivity when searching. Default cd
    @IBInspectable open var searchSensitivity: String = "cd"
    /// Name(s) of the search field(s)
    @IBInspectable open var searchableField: String = "name"
    /// Add search bar in place of navigation bar title
    @IBInspectable open var searchableAsTitle: Bool = true

    /// Name of the field used to sort. (You use multiple field using coma)
    @IBInspectable open var sortField: String = ""
    /// Sort ascending on `sortField`
    @IBInspectable open var sortAscending: Bool = true
    /// If no sort field, use search field as sort field
    @IBInspectable open var searchFieldAsSortField: Bool = true

    /// Active or not a pull to refresh action on list form (default: true)
    @IBInspectable open var hasRefreshControl: Bool = true
    /// Cancel reload data
    var dataSyncTask: Cancellable?
    /// In dev: a view to do not allow action?
    var loadingView: UIView?

    /// Go no the next record.
    @IBOutlet open var nextButton: UIButton?
    /// Go no the previous record.
    @IBOutlet open var previousButton: UIButton?

    /// Optional section for table using one field name
    @IBInspectable open var sectionFieldname: String?
    @IBInspectable open var showSectionBar: Bool = false {
        didSet {
           dataSource?.showSectionBar =  showSectionBar
        }
    }

    public var originalParent: UIViewController?

    // MARK: - override

    final public override func viewDidLoad() {
        super.viewDidLoad()
        initDataSource()
        initComponents()
        onLoad()
        logger.info("ListForm for '\(self.tableName)' table loaded.")

        self.dataSource.performFetch()
        logger.verbose {
            return "source: \(String(describing: self.dataSource)) , count: \(self.dataSource.count)"
        }
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.installBackButton()
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

    override open func willMove(toParent parent: UIViewController?) {
        manageMoreNavigationControllerStyle(parent)
        super.willMove(toParent: parent)
    }

    // MARK: - table view delegate
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // super.tableView(tableView, didSelectRowAt: indexPath)
        if let record = dataSource.record(at: indexPath) {
            onClicked(record: record, at: indexPath)
        }
    }

    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       // super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

       /* XXX Could load more data if pagination
         if (self.dataSource.items.count - triggerTreshold) == indexPath.row
            && indexPath.row > triggerTreshold {
            onScrollDown(...)
        }*/
    }
    //var triggerTreshold = 10

    // MARK: - segue

    /// Prepare transition by providing selected record to detail form.
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // get current index
        guard let indexPath = self.indexPath(for: sender) else { return }
        // create a new entry to bind
        let entry = self.dataSource.entry
        entry.indexPath = indexPath

        // pass to view controllers and views
        if let navigation = segue.destination as? UINavigationController {
            navigation.navigationBar.table = entry
        }
        // by pass navigation controller if any to get real controller
        let destination = segue.destination.firstController
        destination.view.table = entry

        // listen to index path change, to scroll table to new selected record
        entry.add(indexPathObserver: self)
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // Remove the listener
        if let table = self.presentedViewController?.firstController.view.table {
            table.remove(indexPathObserver: self)
        }
        // do dismiss
        super.dismiss(animated: flag, completion: completion)
    }

    override open func show(_ viewController: UIViewController, sender: Any?) {
        self.present(viewController, animated: true, completion: nil)
    }

    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    // MARK: - Events

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

    /// Called before starting a refresh.
    ///
    /// Here you could add a message on refresh control:
    ///  self.refreshControl.title = "Start loading"
    open func onRefreshBegin() {}
    /// Called after a refresh. By default display a message. Override it to change this behaviour.
    open func onRefreshEnd(_ result: DataSync.SyncResult) {
        self.refreshMessage(result)
    }

    open func onSearchBegin() {}
    open func onSearchButtonClicked() {}
    open func onSearchCancel() {}
    open func onSearchFetching() {}

    /// Called after a clicked on a record. 
    /// Will not be call if you override tableView(, didSelectRow) or change tableView delegate.
    open func onClicked(record: Record, at index: IndexPath) {}

    // this function is called when last row displayed. Could do some stuff like loading data...
    func onOpenLastRow() {}

    // MARK: - init

    fileprivate func initDataSource() {
        let dataStore = DataStoreFactory.dataStore // must use same in dataSync
        let fetchedResultsController = dataStore.fetchedResultsController(
            tableName: self.tableName,
            sectionNameKeyPath: self.sectionFieldname,
            sortDescriptors: self.makeSortDescriptors(tableInfo: self.tableInfo))
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
        self.view.table = self.dataSource.entry
    }

    fileprivate func initComponents() {
        self.fixNavigationBarColorFromAsset()
        self.installRefreshControll()
        self.installDataEmptyView()
        self.installSearchBar()
        self.installDataSourcePrefetching()
        //self.installObservers()
    }

    fileprivate func manageMoreNavigationControllerStyle(_ parent: UIViewController?) {
        if parent == nil {
            self.originalParent = self.parent
        } else if let moreNavigationController = parent as? UINavigationController, moreNavigationController.isMoreNavigationController {
            if let navigationController = self.originalParent as? UINavigationController {
                moreNavigationController.navigationBar.copyStyle(from: navigationController.navigationBar)
            }
        }
    }

    // MARK: Install components

    /// Intall a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        if hasRefreshControl {
            self.refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        }
    }

    /// Apple issue with navigation bar color which use asset color as foreground color
    /// If we detect the issue ie. alpha color less than 0.5, we apply your "ForegroundColor" color
    open func fixNavigationBarColorFromAsset() {
        var attributes = self.navigationController?.navigationBar.titleTextAttributes ?? [:]
        if let oldColor = attributes[.foregroundColor] as? UIColor,
            oldColor.rgba.alpha < 0.5, let namedColor = UIColor(named: "ForegroundColor") {
            attributes = [.foregroundColor: namedColor]
            self.navigationController?.navigationBar.titleTextAttributes = attributes
        }
    }

    open func installDataEmptyView() {
        //self.tableView.emptyDataSetSource = self
        //self.tableView.emptyDataSetDelegate = self
    }

    /// Install the seach bar if defined using storyboard IBOutlet
    open func installSearchBar() {
        // Install seachbar into navigation bar if any
        if let searchBar = searchBar, !isSearchBarMustBeHidden {
            if searchBar.superview == nil {
                if searchableAsTitle {
                    self.navigationItem.titleView = searchBar
                } else {
                    let searchController = UISearchController(searchResultsController: nil)
                    searchController.searchResultsUpdater = self
                    searchController.obscuresBackgroundDuringPresentation = false
                    searchController.delegate = self
                    self.navigationItem.searchController = searchController
                    self.definesPresentationContext = true

                    self.searchBar = searchController.searchBar // continue to manage search using listener
                }
            }
        }
        if let subview = self.searchBar.subviews.first {
            if let searchTextField = subview.subviews.compactMap({$0 as? UITextField }).first {
                searchTextField.tintColor = searchTextField.textColor
            }
        }
        self.searchBar?.delegate = self

        if isSearchBarMustBeHidden {
            searchBar.isHidden = true
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

    // MARK: QMobile Event

    func installObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(dataSyncEvent(_:)), name: .dataSyncForTableBegin, object: ApplicationDataSync.dataSync)
        NotificationCenter.default.addObserver(self, selector: #selector(dataSyncEvent(_:)), name: .dataSyncForTableSuccess, object: ApplicationDataSync.dataSync)
        NotificationCenter.default.addObserver(self, selector: #selector(dataSyncEvent(_:)), name: .dataSyncForTableFailed, object: ApplicationDataSync.dataSync)
    }

    @objc func dataSyncEvent(_ notification: Notification) {
        guard let table = notification.userInfo?["table"] as? Table, self.table == table else {
            return
        }
        switch notification.name {
        case .dataSyncForTableBegin:
            break
        case .dataSyncForTableSuccess, .dataSyncForTableFailed:
            break
        default:
            return
        }
    }

    open func dataSourceWillChangeContent(_ dataSource: DataSource) {
        /*loadingView = UIView(frame: self.view.frame)

        loadingView?.backgroundColor = .red

        let parentView: UIView = (self.navigationController?.view ?? self.view)

        parentView.addSubview(loadingView!)
        parentView.bringSubviewToFront(loadingView!)*/
    }
    //@objc func dataSource(_ dataSource: DataSource, didInsertRecord record: Record, atIndexPath indexPath: IndexPath)
    //@objc func dataSource(_ dataSource: DataSource, didUpdateRecord record: Record, atIndexPath indexPath: IndexPath)
    //@objc func dataSource(_ dataSource: DataSource, didDeleteRecord record: Record, atIndexPath indexPath: IndexPath)
    //@objc func dataSource(_ dataSource: DataSource, didMoveRecord record: Record, fromIndexPath oldIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath)

    open func dataSourceDidChangeContent(_ dataSource: DataSource) {
        DispatchQueue.main.async {
            self.loadingView?.removeFromSuperview()
        }
    }

    // MARK: - Utility

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

    public func scrollToRecord(_ record: Record, at scrollPosition: UITableView.ScrollPosition = .top) { // more swift notation: scroll(to record: Record
        if let indexPath = dataSource?.indexPath(for: record) {
            self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }
    }

    public func showDetailsForm(_ record: Record, animated: Bool = true, scrollPosition: UITableView.ScrollPosition = .middle) {
        if let indexPath = dataSource?.indexPath(for: record) {
            self.tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

}

// MARK: - IBAction
extension ListFormTable {

    /// Action on pull to refresh
    @IBAction open func refresh(_ sender: Any?) {
        onRefreshBegin()

        let endRefreshing: (DataSync.SyncResult) -> Void = { result in
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl?.endRefreshing()
                self?.onRefreshEnd(result)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dataSyncTask = self.doRefresh(sender, self, endRefreshing)
        }
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

// MARK: - Extension
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

extension ListFormTable: IndexPathObserver {

    func willChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
    }
    func didChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
        if let indexPath = indexPath {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

}

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
        searchBar.endEditing(true)
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
        onSearchCancel()
    }

    // Function to do search

    func performSearch(_ searchText: String) {
        // XXX could add other predicate
        if !isSearchBarMustBeHidden {
            // Create the search predicate
            dataSource?.predicate = createSearchPredicate(searchText, tableInfo: tableInfo)

            // Event
            onSearchFetching()
        }
        // XXX API here could load more from network
    }

    public func updateSearchResults(for searchController: UISearchController) {
        //let searchBar = searchController.searchBar
        //if let searchText = searchBar.text {
            //performSearch(searchText) // already done by search bar listener
        //}
    }

}
