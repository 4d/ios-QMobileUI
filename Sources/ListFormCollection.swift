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

    @IBInspectable public var selectedSegueIdentifier: String = "showDetail"

    @IBInspectable public var hasRefreshControl: Bool = true
     public var refreshControl: UIRefreshControl?
    /// Optional section for table using one field name
    @IBInspectable public var sectionFieldname: String?

    @IBOutlet public var searchBar: UISearchBar!
    public var searchActive: Bool = false
    @IBInspectable public var searchableField: String = "name"

    // MARK: override
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = self.collectionView  else { fatalError("CollectionView is nil") }

        let fetchedResultsController = dataStore.fetchedResultsController(tableName: self.tableName, sectionNameKeyPath: self.sectionFieldname)
        dataSource = DataSource(collectionView: collectionView, fetchedResultsController: fetchedResultsController)

        dataSource.collectionConfigurationBlock = { [unowned self] cell, record, index in
            self.configureListFormView(cell, record, index)
        }

        self.view.table = DataSourceEntry(dataSource: self.dataSource)

        searchBar?.delegate = self

        self.installRefreshControll()
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == selectedSegueIdentifier {*/ // code commented, here we can filter on segue name
            if let indexPath = self.indexPath(for: sender) {
                let table = DataSourceEntry(dataSource: self.dataSource)
                table.indexPath = indexPath

                var destination = segue.destination
                if let navigation = destination as? UINavigationController {
                    navigation.navigationBar.table = table
                    navigation.navigationBar.record = table.record
                    if let first = navigation.viewControllers.first {
                        destination = first
                    }
                }
                destination.view.table = table
                destination.view.record = table.record
            }
        /*}*/
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // For a selection default behaviour is to show detail...
        self.performSegue(withIdentifier: selectedSegueIdentifier, sender: collectionView)
    }

    /// Intall a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        if hasRefreshControl {
            self.collectionView?.alwaysBounceVertical = true

            self.refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            // swiftlint:disable force_cast
            self.collectionView?.addSubview(refreshControl!)
        }
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
        // TODO refresh using remote source
        DispatchQueue.main.after(2) {
            self.dataSource.performFetch()
            self.refreshControl?.endRefreshing()
        }
    }
}

// MARK: DataSourceSearchable
extension ListFormCollection: DataSourceSearchable {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // XXX could add other predicate

        if !searchText.isEmpty {
            dataSource?.predicate = NSPredicate(format: "\(searchableField) contains[c] %@", searchText)
        } else {
            dataSource?.predicate = nil
        }
        dataSource?.performFetch()

        // XXX API here could load more from network
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        dataSource?.predicate = nil
        dataSource?.performFetch()
    }

}
