//
//  ListFormTable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

import Moya
import SwiftMessages

@IBDesignable
open class ListFormTable: UITableViewController, ListFormSearchable { // swiftlint:disable:this type_body_length

    public var dataSource: DataSource? {
        return tableDataSource
    }
    public var tableDataSource: TableDataSource?
    public var formContext: FormContext?

    @IBInspectable open var selectedSegueIdentifier: String = "showDetails"

    @IBOutlet open var searchBar: UISearchBar!
    public var searchActive: Bool = false
    /// Operator used to search. contains, beginswith, endswith. Default contains
    @IBInspectable open var searchOperator: String = "contains" {
        didSet {
            assert(["contains", "beginswith", "endswith"].contains(searchOperator.lowercased()))
        }
    }
    /// Case sensitivity when searching. Default cd
    @IBInspectable open var searchSensitivity: String = "cd"
    /// Name(s) of the search field(s)
    @IBInspectable open var searchableField: String = "name"
    /// Add search bar in place of navigation bar title (default: `true`)
    @IBInspectable open var searchableAsTitle: Bool = true
    /// Keep search bar if scrolling (default: `true`) - only if `searchableAsTitle` is `false`
    @IBInspectable open var searchableWhenScrolling: Bool = true
    /// Hide navigation bar when searching (default: `true`) - only if `searchableAsTitle` is `false`
    @IBInspectable open var searchableHideNavigation: Bool = true
    /// Activate search with code scanner
    @IBInspectable open var searchUsingCodeScanner: Bool = false
    /// Open detail form if search result in one record
    @IBInspectable open var searchOpenIfOne: Bool = false
    var searchOpenIfOneRestoreValue: Bool = false
    /// When there is no more things to search, apply still a predicate (default: nil)
    open var defaultSearchPredicate: NSPredicate?
    /// Experimental: add core data search with a segmented control UI
    open var searchScopes: [(String, NSPredicate)] = []

    /// Name of the field used to sort. (You use multiple field using coma)
    @IBInspectable open var sortField: String = ""
    /// Sort ascending on `sortField`
    @IBInspectable open var sortAscending: Bool = true
    /// If no sort field, use search field as sort field
    @IBInspectable open var searchFieldAsSortField: Bool = true

    /// Active or not a pull to refresh action on list form (default: true)
    @IBInspectable open var hasRefreshControl: Bool = true
    /// In dev: a view to do not allow action?
    var loadingView: UIView?
    /// Cancel reload data
    var dataSyncTask: Cancellable?

    /// Go no the next record.
    @IBOutlet open var nextButton: UIButton?
    /// Go no the previous record.
    @IBOutlet open var previousButton: UIButton?

    /// Optional section for table using one field name
    @IBInspectable open var sectionFieldname: String?
    /// Localize section with formatter.
    @IBInspectable open var sectionFieldFormatter: String?
    @IBInspectable open var showSectionBar: Bool = false {
        didSet {
           dataSource?.showSectionBar =  showSectionBar
        }
    }

    public var originalParent: UIViewController?
    public var scrollView: UIScrollView? {
        return self.tableView
    }

    public var inDataSync: Bool = false {
        didSet {
            updateProgressBar()
        }
    }
    public var isViewVisible: Bool = false {
        didSet {
            updateProgressBar()
        }
    }

    public var isScrolling: Bool = false {
        didSet {
            updateProgressBar()
        }
    }

    // MARK: - override

    final public override func viewDidLoad() {
        super.viewDidLoad()
        UITableViewCell.swizzle_adjustSwipeActionTextColors()
        initDataSource()
        initComponents()
        onLoad()
        logger.info("ListForm for '\(self.tableName)' table loaded.")

        self.dataSource?.performFetch()
        if logger.isEnabledFor(level: .verbose) {
            logger.verbose("source: \(String(describing: self.dataSource)) , count: \(String(describing: self.dataSource?.count))")
        }
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.installBackButton()
        self.addEllipsisView()
        self.initRefreshControll()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        inDataSync = !ApplicationDataSync.instance.dataSync.isCancelled
        initBackButton()
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unitRefreshControll()
        self.removeEllipsisView()
        isViewVisible = false
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

    /*override open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }*/

    // MARK: - table view delegate
  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // super.tableView(tableView, didSelectRowAt: indexPath)
        guard let record = dataSource?.record(at: indexPath) else { return }
        onClicked(record: record, at: indexPath)
    }

    /*override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

         XXX Could load more data if pagination
         if (self.dataSource.items.count - triggerTreshold) == indexPath.row
         && indexPath.row > triggerTreshold {
         onScrollDown(...)
         }
    }*/

    // MARK: - UITableViewUISwipeActionsConfigurationRowAction

    /// Provide action as swipe action
    override open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let actionContext = self.actionContext(forRowAt: indexPath),
              let contextualActions = tableView.swipeActions(with: actionContext, at: indexPath, withMore: true) else { return .empty }
        let configuration = UISwipeActionsConfiguration(actions: contextualActions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    // or leadingSwipeActionsConfigurationForRowAt?

    /// Fix text color of swipe actions
    fileprivate func fixSwipeActionTextColor(_ tableView: UITableView, _ indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            tableView.cellForRow(at: indexPath)?.layoutIfNeeded()
        }
    }

    override open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        super.tableView(tableView, willBeginEditingRowAt: indexPath)
        fixSwipeActionTextColor(tableView, indexPath)
    }

    // override open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {}

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isEditing {
            // we close editing(swipe action) as workaround to text color fix (alternative could be get edited row index path and call fixSwipeActionTextColor
            self.tableView.setEditing(false, animated: true)
        }
    }

    // MARK: - segue

    /// Prepare transition by providing selected record to detail form.
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = self.indexPath(for: sender) else {
            if segue.identifier == selectedSegueIdentifier {
                logger.warning("No collection index found for \(String(describing: sender)).")
            }
            return
        }
        let destination = segue.destination.firstController

        if let destination = destination as? DetailsForm {
            if let relationInfoUI = sender as? RelationInfoUI {
                ApplicationCoordinator.prepare(from: self, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
            } else {
                ApplicationCoordinator.prepare(from: self, at: indexPath, to: destination)
            }
        } else if let destination = destination as? ListForm {
            guard let relationInfoUI = sender as? RelationInfoUI else {
                logger.warning("No information about the relation in UI")
                return
            }
            ApplicationCoordinator.prepare(from: self, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
        }
        segue.fix()
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

    public override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isScrolling = true
    }

    public override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.isScrolling = false
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
    open func onSearchFetching() {
        checkIfOpenFirstResult()
    }
    open func onSearchCodeScanClicked() {
        showCodeScanController()
    }

    /// Called after a clicked on a record. 
    /// Will not be call if you override tableView(, didSelectRow) or change tableView delegate.
    open func onClicked(record: Record, at index: IndexPath) {}

    // this function is called when last row displayed. Could do some stuff like loading data...
    func onOpenLastRow() {}

    // MARK: - init

    private func initDataSource() {
        let dataStore = DataStoreFactory.dataStore // must use same in dataSync
        let fetchedResultsController = dataStore.fetchedResultsController(
            tableName: self.tableName,
            sectionNameKeyPath: self.sectionFieldname,
            sortDescriptors: self.makeSortDescriptors(tableName: self.tableName))
        tableDataSource = TableDataSource(tableView: self.tableView, fetchedResultsController: fetchedResultsController)
        tableDataSource?.contextPredicate = formContext?.predicate
        tableDataSource?.showSectionBar = showSectionBar
        tableDataSource?.sectionFieldFormatter = sectionFieldFormatter

        tableDataSource?.tableConfigurationBlock = { [weak self] cell, record, index in
            self?.configureListFormView(cell, record, index)

            if index.row == self?.tableView.indexPathsForVisibleRows?.last?.row ?? -1 {
                self?.onOpenLastRow()
            }
        }

        dataSource?.delegate = self

        // self.tableView.delegate = self
        self.view.table = self.dataSource?.entry()
    }

    private func initComponents() {
        self.fixNavigationBarColor()
        self.installRefreshControll()
        self.installDataEmptyView()
        self.installSearchBar()
        self.installDataSourcePrefetching()
        self.installObservers(#selector(self.onDataSyncEvent(_:))) // pass selector because protocol not objc
        if let previousTitle = self.formContext?.previousTitle {
            self.navigationItem.title = previousTitle
        }
        self.installNatigationMenu()
    }

    // MARK: Install components

    /// Install a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        guard hasRefreshControl else { return }
        self.refreshControl = UIRefreshControl()
        if let navigationBar = self.navigationController?.navigationBar, let tintColor = navigationBar.tintColor, navigationBar.prefersLargeTitles {
            refreshControl?.tintColor = tintColor
        }
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }

    fileprivate func initRefreshControll() {
        guard hasRefreshControl else { return }
        endRefreshing(Notification(name: .init(rawValue: "init")))
        let center: NotificationCenter = .default
        center.addObserver(self,
                           selector: #selector(endRefreshing),
                           name: UIApplication.willEnterForegroundNotification,
                           object: nil)
    }

    @objc public func endRefreshing(_ notification: Notification) {
        guard hasRefreshControl else { return }
        DispatchQueue.main.after(0.2) { [weak self] in
            guard let refreshControl = self?.refreshControl else { return }
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            } else if !refreshControl.isHidden {
                refreshControl.beginRefreshing()
                refreshControl.endRefreshing()
            }
        }
    }

    private func unitRefreshControll() {
        guard hasRefreshControl else { return }
        let center: NotificationCenter = .default
        center.removeObserver(self,
                              name: UIApplication.willEnterForegroundNotification,
                              object: nil)
    }

    open func installDataEmptyView() {
        // self.tableView.emptyDataSetSource = self
        // self.tableView.emptyDataSetDelegate = self
    }

    /// Install the seach bar if defined using storyboard IBOutlet
    open func installSearchBar() {
        doInstallSearchBar()
        self.searchOpenIfOneRestoreValue=self.searchOpenIfOne
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

    @objc open func onDataSyncEvent(_ notification: Notification) {
        dataSyncEvent(notification)
    }

    open func dataSourceWillChangeContent(_ dataSource: DataSource) {
        /*loadingView = UIView(frame: self.view.frame)

        loadingView?.backgroundColor = .red

        let parentView: UIView = (self.navigationController?.view ?? self.view)

        parentView.addSubview(loadingView!)
        parentView.bringSubviewToFront(loadingView!)*/
    }
    // @objc func dataSource(_ dataSource: DataSource, didInsertRecord record: Record, atIndexPath indexPath: IndexPath)
    // @objc func dataSource(_ dataSource: DataSource, didUpdateRecord record: Record, atIndexPath indexPath: IndexPath)
    // @objc func dataSource(_ dataSource: DataSource, didDeleteRecord record: Record, atIndexPath indexPath: IndexPath)
    // @objc func dataSource(_ dataSource: DataSource, didMoveRecord record: Record, fromIndexPath oldIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath)

    open func dataSourceDidChangeContent(_ dataSource: DataSource) {
        /*DispatchQueue.main.async {
         //self.loadingView?.removeFromSuperview()
         }*/
    }

    func checkIfOpenFirstResult() {
        if self.searchOpenIfOne {
            foreground { [self] in
                if self.dataSource?.fetchedRecords.count == 1/*, let record = self.dataSource?.fetchedRecords.first*/ {
                    // self.tableView.selectRow(at: .zero, animated: false, scrollPosition: .none)
                    // self.tableView(self.tableView, didSelectRowAt: .zero)
                    self.performSegue(withIdentifier: self.selectedSegueIdentifier, sender: self.tableView.visibleCells.first)
                }
                self.searchOpenIfOne = self.searchOpenIfOneRestoreValue
            }
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
        } else if let view = cell as? UIView, let cell = view.parentCellView as? UITableViewCell {
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

    // MARK: - animation

    /// Experimental method to make some animation on table when appear.
    /// Call it in viewWillAppear
    public func animateTable() {
        guard let tableView = self.tableView else {
            return
        }
        tableView.reloadData()

        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height

        for cell in cells {
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }

        var index = 0
        for cell in cells {
            let cell = cell
            UIView.animate(withDuration: 1.0, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)

            index += 1
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
        if let indexPath = self.dataSource?.lastIndexPath {
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

    public func installDataSourcePrefetching() {
        self.tableView.prefetchDataSource = self

        // get all image urls from records
        // let urls = records.flatMap {  }
        // ImagePrefetcher(urls: urls).start()
    }

    open func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

    }

}

// MARK: IndexPathObserver 
extension ListFormTable {

    public func willChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
    }
    public func didChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
        if let indexPath = indexPath {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

}

// Must be implement as @objc method, so not in protocol currently...
extension ListFormTable: DataSourceSearchable {

    /// Perform a seach when text change
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
       do_searchBar(searchBar, textDidChange: searchText)
    }

    /// A search begin. Cancel button is displayed.
    /// You can receive this information by overriding `onSearchBegin`
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        do_searchBarTextDidBeginEditing(searchBar)
    }

    // Search button is clicked. You can receive this information by overriding `onSearchButtonClicked`
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        do_searchBarSearchButtonClicked(searchBar)
    }

    /// Cancel button is clicked, cancel the search.
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        do_searchBarCancelButtonClicked(searchBar)
    }

    public func updateSearchResults(for searchController: UISearchController) {
        do_updateSearchResults(for: searchController)
    }

    public func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        do_searchBarBookmarkButtonClicked(for: searchBar)
    }

    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        do_searchScopeChange(searchBar, to: selectedScope)
    }
}
