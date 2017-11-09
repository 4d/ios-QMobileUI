//
//  CollectionViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

@IBDesignable
open class ListFormCollection: UICollectionViewController, ListForm {

    public var dataSource: DataSource! = nil

    @IBInspectable open var selectedSegueIdentifier: String = "showDetail"

    @IBOutlet open var nextButton: UIButton?
    @IBOutlet open var previousButton: UIButton?
    @IBInspectable open var hasRefreshControl: Bool = false
    @IBInspectable open var searchOperator: String = "contains" // beginwith, endwitch
    @IBInspectable open var searchSensitivity: String = "cd"
     public var refreshControl: UIRefreshControl?
    /// Optional section for table using one field name
    @IBInspectable open var sectionFieldname: String?

    @IBOutlet open var searchBar: UISearchBar!
    public var searchActive: Bool = false
    @IBInspectable open var searchableField: String = "name"

    @IBInspectable open var showSectionBar: Bool = false {
        didSet {
            dataSource?.showSectionBar =  showSectionBar
        }
    }

    /// On click execute transition to show record details.
    /// Set to false, to not execute transition and manage your own code in onClicked()
    @IBInspectable open var onClickShowDetail: Bool = true

    // MARK: override
    final public override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = self.collectionView  else { fatalError("CollectionView is nil") }

        let fetchedResultsController = dataStore.fetchedResultsController(tableName: self.tableName, sectionNameKeyPath: self.sectionFieldname)
        dataSource = DataSource(collectionView: collectionView, fetchedResultsController: fetchedResultsController)
        dataSource.showSectionBar = showSectionBar

        dataSource.collectionConfigurationBlock = { [unowned self] cell, record, index in
            self.configureListFormView(cell, record, index)
        }

        self.view.table = DataSourceEntry(dataSource: self.dataSource)

        dataSource.delegate = self
        self.installRefreshControll()
        self.installDataEmptyView()
        self.installSearchBar()
        self.installDataSourcePrefetching()
        self.installBackButton()

        onLoad()
        if isSearchBarMustBeHidden {
            self.searchBar.isHidden = true
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

    // MARK: segue

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == selectedSegueIdentifier {*/ // code commented, here we can filter on segue name
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
        /*}*/
    }

    // MARK: Collection View

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // super.collectionView(collectionView, didSelectItemAt: indexPath)
        // For a selection default behaviour is to show detail...

        if onClickShowDetail {
            self.performSegue(withIdentifier: selectedSegueIdentifier, sender: collectionView)
        }
        if let record = dataSource.record(at: indexPath) {
            onClicked(record: record, at: indexPath)
        }
    }

    override open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)

        // could be overrided to add animation on cell appear
        // could do it here according to a property IB
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

    // MARK: Install components

    /// Intall a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        if hasRefreshControl {
            self.collectionView?.alwaysBounceVertical = true

            self.refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            if let refreshControl = refreshControl {
                self.collectionView?.addSubview(refreshControl)
            }
        }
    }

    open func installDataEmptyView() {
        //self.collectionView?.emptyDataSetSource = self
       // self.collectionView?.emptyDataSetDelegate = self
    }

    open func installSearchBar() {
        // Install seachbar into navigation bar if any
        if let searchBar = searchBar {
            searchBar.delegate = self
            if searchBar.superview == nil {
                self.navigationItem.titleView = searchBar
            }
        }
    }

    open func installBackButton() {
        checkBackButton()
    }

    open func indexPath(for cell: Any?) -> IndexPath? {
        if let cell = cell as? UICollectionViewCell {
            return self.collectionView?.indexPath(for: cell)
        }
        return nil
    }

    /// The table name for this controller.
    /// By default generated from first word in controller name.
    open var tableName: String {
        return defaultTableName
    }

    // MARK: IBActions
    @IBAction func refresh(_ sender: Any?) {
        onRefreshBegin()

        //let dataSync = ApplicationLoadDataStore.castedInstance.dataSync
        // _ = dataSync.sync { _ in
        // self.dataSource.performFetch()
        self.refreshControl?.endRefreshing()
        self.onRefreshEnd()
        //}
    }

    /// Scroll to the top of the current list form
    @IBAction open func scrollToTheTop(_ sender: Any?) {
        collectionView?.setContentOffset(CGPoint.zero, animated: true)
    }

    /// Scrol to the bottom of the current list form
    @IBAction open func scrollToLastRow(_ sender: Any?) {
        if let indexPath = self.dataSource.lastIndexPath {
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    /// Scroll to the specific record
    public func scrollToRecord(_ record: Record, at scrollPosition: UICollectionViewScrollPosition = .top) { // more swift notation: scroll(to record: Record
        if let indexPath = dataSource?.indexPath(for: record) {
            self.collectionView?.scrollToItem(at: indexPath, at: scrollPosition, animated: true)
        }
    }

    /// Show the detail form the specific record
    public func showDetailForm(_ record: Record, animated: Bool = true, scrollPosition: UICollectionViewScrollPosition = .centeredVertically) {
        if let indexPath = dataSource?.indexPath(for: record) {
            self.collectionView?.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

    @IBAction open func searchBarFirstResponder(_ sender: Any?) {
        self.searchBar?.resignFirstResponder()
    }
    @IBAction open func searchBarEndEditing(_ sender: Any?) {
        self.searchBar?.endEditing(true)
    }

    //action go to next section
    @IBAction func nextHeader(_ sender: UIButton) {
        let lastSectionIndex = collectionView?.numberOfSections
        let firstVisibleIndexPath = self.collectionView?.indexPathsForVisibleItems[1] //self.collectionView.indexPathsForVisibleRows?[1]
        if (firstVisibleIndexPath?.section)! < lastSectionIndex! - 1 {
            previousButton?.alpha = 1
            nextButton?.alpha = 1
            self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: (firstVisibleIndexPath?.section)!-1), at: .top, animated: true)
        } else {
            nextButton?.alpha = 0.2
        }
    }

    //action back to previous section
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

// MARK: DataSourceSearchable
import Kingfisher
extension ListFormCollection: UICollectionViewDataSourcePrefetching {

    open func installDataSourcePrefetching() {
        self.collectionView?.prefetchDataSource = self
    }

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        //let records = indexPaths.flatMap {dataSo

        // get all image urls from records
        //let urls: [URL] = [] // records.flatMap {  }
        //let imagePrefetcher = ImagePrefetcher(urls: urls)
        //imagePrefetcher.start()
    }

    // public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {}
}

// MARK: DataSourceSearchable
extension ListFormCollection: DataSourceSearchable {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // XXX could add other predicate
        searchBar.showsCancelButton = true
        performSearch(searchText)
    }
    func performSearch(_ searchText: String) {
        if !isSearchBarMustBeHidden {
            if !searchText.isEmpty {
                assert(["contains", "beginwith", "endwitch"].contains(searchOperator.lowercased()))
                assert(self.table?.attributes[searchableField] != nil,
                       "Configured field to search '\(searchableField)' is not in table field.\n Check search identifier list form storyboard for class \(self).\n Table: \(String(unwrappedDescrib: table))" )
                dataSource?.predicate = NSPredicate(format: "\(searchableField) \(searchOperator)[\(searchSensitivity)] %@", searchableField, searchText)
            } else {
                dataSource?.predicate = nil
            }
            dataSource?.performFetch()
        }

        // XXX API here could load more from network
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        onSearchBegin()

        searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        onSearchButtonClicked()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: false)
        searchBar.endEditing(true)
        dataSource?.predicate = nil
        dataSource?.performFetch()
        onSearchCancelButtonClicked()
    }

}
