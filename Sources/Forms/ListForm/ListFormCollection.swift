//
//  ListFormCollection.swift
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
open class ListFormCollection: UICollectionViewController, ListFormSearchable { // swiftlint:disable:this type_body_length

    public var dataSource: DataSource? {
        return collectionDataSource
    }
    public var collectionDataSource: CollectionDataSource?
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
    /// The pull to refresh control
    public var refreshControl: UIRefreshControl?
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

    /// On click execute transition to show record details by code if there is no segue in storyboard.
    /// Set to false, to not execute transition and manage your own code in onClicked()
    @IBInspectable open var onClickShowDetails: Bool = false

    public var originalParent: UIViewController?
    public var scrollView: UIScrollView? {
        return self.collectionView
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
        initDataSource()
        initComponents()
        onLoad()
        logger.info("ListForm for '\(self.tableName)' table loaded.")

        self.dataSource?.performFetch()
        logger.verbose({
            return "source: \(String(describing: self.dataSource)) , count: \(String(describing: self.dataSource?.count))"
        })
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.installBackButton()
        self.initRefreshControll()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unitRefreshControll()
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

    // MARK: - segue

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

    // MARK: - Collection View

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // super.collectionView(collectionView, didSelectItemAt: indexPath)
        // For a selection default behaviour is to show detail...

        if onClickShowDetails {
            self.performSegue(withIdentifier: selectedSegueIdentifier, sender: self.collectionView(collectionView, cellForItemAt: indexPath))
        }
        if let record = dataSource?.record(at: indexPath) {
            onClicked(record: record, at: indexPath)
        }
    }

    override open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)

        // could be overrided to add animation on cell appear
        // could do it here according to a property IB
    }
    override open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.

        // (cell as! CollectionViewCell).cellImageView.kf.cancelDownloadTask()
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

    // MARK: - Init

    fileprivate func initDataSource() {
        guard let collectionView = self.collectionView  else { fatalError("CollectionView is nil") }
        let dataStore = DataStoreFactory.dataStore // must use same in dataSync
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: self.tableName,
                                                                          sectionNameKeyPath: self.sectionFieldname,
                                                                          sortDescriptors: self.makeSortDescriptors(tableInfo: self.tableInfo))
        collectionDataSource = CollectionDataSource(collectionView: collectionView, fetchedResultsController: fetchedResultsController)
        collectionDataSource?.contextPredicate = formContext?.predicate
        collectionDataSource?.showSectionBar = showSectionBar
        collectionDataSource?.sectionFieldFormatter = sectionFieldFormatter

        dataSource?.performFetch()

        collectionDataSource?.collectionConfigurationBlock = { [unowned self] cell, record, index in
            self.configureListFormView(cell, record, index)
        }

        self.view.table = self.dataSource?.entry()

        dataSource?.delegate = self
    }

    fileprivate func initComponents() {
        self.fixNavigationBarColor()
        self.installRefreshControll()
        self.installDataEmptyView()
        self.installSearchBar()
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
        self.collectionView?.alwaysBounceVertical = true

        self.refreshControl = UIRefreshControl()
        if let navigationBar = self.navigationController?.navigationBar, let tintColor = navigationBar.tintColor, navigationBar.prefersLargeTitles {
            refreshControl?.tintColor = tintColor
        }
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if let refreshControl = refreshControl {
            self.collectionView?.addSubview(refreshControl)
        }
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

    fileprivate func unitRefreshControll() {
        guard hasRefreshControl else { return }
        let center: NotificationCenter = .default
        center.removeObserver(self,
                              name: UIApplication.willEnterForegroundNotification,
                              object: nil)
    }

    open func installDataEmptyView() {
        // self.collectionView?.emptyDataSetSource = self
        // self.collectionView?.emptyDataSetDelegate = self
    }

    open func installSearchBar() {
        doInstallSearchBar()
        self.searchOpenIfOneRestoreValue=self.searchOpenIfOne
    }

    open func installBackButton() {
        checkBackButton()
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
            foreground {
                if self.dataSource?.fetchedRecords.count == 1/*, let record = self.dataSource?.fetchedRecords.first*/ {
                    // self.collectionView.selectRow(at: .zero, animated: false, scrollPosition: .none)
                    // self.collectionView(self.collectionView, didSelectRowAt: .zero)
                    self.performSegue(withIdentifier: self.selectedSegueIdentifier, sender: self.collectionView.visibleCells.first)
                }
                self.searchOpenIfOne = self.searchOpenIfOneRestoreValue
            }
        }
    }

    // MARK: - Utility

    open func indexPath(for cell: Any?) -> IndexPath? {
        if let cell = cell as? UICollectionViewCell {
            return self.collectionView?.indexPath(for: cell)
        } else if let collection = cell as? UICollectionView {
            logger.warning("Expected a UICollectionViewCell but receive UICollectionView \(collection). Maybe segue is in wrong object")
            return nil
        } else if let view = cell as? UIView, let cell = view.parentCellView as? UICollectionViewCell {
            return self.collectionView?.indexPath(for: cell)
        }
        return nil
    }

    /// The table name for this controller.
    /// By default generated from first word in controller name.
    open var tableName: String {
        return defaultTableName
    }

    /// Scroll to the specific record
    public func scrollToRecord(_ record: Record, at scrollPosition: UICollectionView.ScrollPosition = .top) { // more swift notation: scroll(to record: Record
        if let indexPath = dataSource?.indexPath(for: record) {
            self.collectionView?.scrollToItem(at: indexPath, at: scrollPosition, animated: true)
        }
    }

    /// Show the detail form the specific record
    public func showDetailsForm(_ record: Record, animated: Bool = true, scrollPosition: UICollectionView.ScrollPosition = .centeredVertically) {
        if let indexPath = dataSource?.indexPath(for: record) {
            self.collectionView?.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

}

// MARK: - IBAction
extension ListFormCollection {

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

    /// Scroll to the top of the current list form
    @IBAction open func scrollToTheTop(_ sender: Any?) {
        collectionView?.setContentOffset(CGPoint.zero, animated: true)
    }

    /// Scrol to the bottom of the current list form
    @IBAction open func scrollToLastRow(_ sender: Any?) {
        if let indexPath = self.dataSource?.lastIndexPath {
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    @IBAction open func searchBarFirstResponder(_ sender: Any?) {
        self.searchBar?.resignFirstResponder()
    }

    @IBAction open func searchBarEndEditing(_ sender: Any?) {
        self.searchBar?.endEditing(true)
    }

    // action go to next section
    @IBAction func nextHeader(_ sender: UIButton) {
        let lastSectionIndex = collectionView?.numberOfSections
        let firstVisibleIndexPath = self.collectionView?.indexPathsForVisibleItems[1] // self.collectionView.indexPathsForVisibleRows?[1]
        if (firstVisibleIndexPath?.section)! < lastSectionIndex! - 1 {
            previousButton?.alpha = 1
            nextButton?.alpha = 1
            self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: (firstVisibleIndexPath?.section)!-1), at: .top, animated: true)
        } else {
            nextButton?.alpha = 0.2
        }
    }

    // action back to previous section
    @IBAction func previousItem(_ sender: Any?) {
        let firstVisibleIndexPath = collectionView?.indexPathsForVisibleItems[1]
        if (firstVisibleIndexPath?.section)! > 0 {
            previousButton?.alpha = 1
            nextButton?.alpha = 1
            self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: (firstVisibleIndexPath?.section)!-1), at: .top, animated: true)
        } else {
            previousButton?.alpha = 0.2
        }
    }
}

// MARK: - Extension

// MARK: IndexPathObserver
extension ListFormCollection {

    open func willChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
    }
    open func didChangeIndexPath(from previous: IndexPath?, to indexPath: IndexPath?) {
        if let indexPath = indexPath {
            self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }

}

import Kingfisher
extension ListFormCollection: UICollectionViewDataSourcePrefetching {

    open func installDataSourcePrefetching() {
        self.collectionView?.prefetchDataSource = self
    }

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // let records = indexPaths.flatMap {dataSo

        // get all image urls from records
        // let urls: [URL] = [] // records.flatMap {  }
        // let imagePrefetcher = ImagePrefetcher(urls: urls)
        // imagePrefetcher.start()
    }

    // public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {}
}

extension ListFormCollection: DataSourceSearchable {

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
