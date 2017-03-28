//
//  ListFormTableViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

@IBDesignable
open class ListFormTableViewController: UITableViewController, ListFormViewController {

    public var dataSource: DataSource! = nil

    @IBInspectable public var selectedSegueIdentifier: String = "showDetail"
    @IBInspectable public var hasRefreshControl: Bool = true
    /// Optional section for table using one field name
    @IBInspectable public var sectionFieldname: String?
    @IBOutlet public var searchBar: UISearchBar!

    public var searchActive: Bool = false
    @IBInspectable public var searchableField: String = "name" 

    open override func viewDidLoad() {
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: self.tableName, sectionNameKeyPath: self.sectionFieldname)
        dataSource = DataSource(tableView: self.tableView, fetchedResultsController: fetchedResultsController)

        dataSource.tableConfigurationBlock = { [unowned self] cell, record, index in
            self.configureListFormView(cell, record, index)
        }

        self.view.table = DataSourceEntry(dataSource: self.dataSource)

        searchBar?.delegate = self

        installRefreshControll()
    }

    open func indexPath(for cell: Any?) -> IndexPath? {
        if let cell = cell as? UITableViewCell {
            // return self.tableView?.indexPathForSelectedRow
            return self.tableView?.indexPath(for: cell)
        }
        return nil
    }

    /// Intall a refresh controll. You could change implementation by overriding or deactivate using `hasRefreshControl` attribute
    open func installRefreshControll() {
        if hasRefreshControl {
            self.refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        }
    }

    /// The table name for this controller.
    /// By default generated from first word in controller name.
    open var tableName: String {
        return defaultTableName
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == selectedSegueIdentifier {*/
            if let indexPath = self.indexPath(for: sender) {
                let table = DataSourceEntry(dataSource: self.dataSource)
                table.indexPath = indexPath
                segue.destination.view.table = table
                segue.destination.view.record = table.record
            }
        /*} else {
            logger.warning("Transition \(segue.identifier) unknown. Please use \(self.selectedSegueIdentifier) to transmit data to next controller")
        }*/
    }

    @IBAction func refresh(_ sender: Any?) {
        // TODO refresh using remote source
        DispatchQueue.main.after(2) {
            self.dataSource.performFetch()
            self.refreshControl?.endRefreshing()
        }
    }

    /*public func scrollToLastRow(animated:Bool) {
        self.scrollToRow(at: dataSource.lastIndexPath, at: .bottom, animated: animated)
    }*/

}

// MARK: DataSourceSearchable
extension ListFormTableViewController: DataSourceSearchable {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // XXX could add other predicate
        
        if !searchText.isEmpty {
            
            dataSource?.predicate = NSPredicate(format: "\(searchableField) contains[c] %@", searchText)
        } else {
            dataSource?.predicate = nil
        }
        dataSource?.performFetch()
        
        // TODO API here could load more from network
    }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
}
