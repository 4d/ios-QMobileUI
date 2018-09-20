//
//  DataSourceDelegate.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

/// Do some customization on DataSource.
/// See `UITableViewDataSource` or `UICollectionViewDataSource`.
@objc public protocol DataSourceDelegate: NSObjectProtocol {

    // MARK: Cell Configuration
    @objc optional func dataSource(_ dataSource: DataSource, cellIdentifierFor indexPath: IndexPath) -> String
    @objc optional func dataSource(_ dataSource: DataSource, configureTableViewCell cell: UITableViewCell, withRecord record: Record, atIndexPath indexPath: IndexPath)
    @objc optional func dataSource(_ dataSource: DataSource, configureCollectionViewCell cell: UICollectionViewCell, withRecord record: Record, atIndexPath indexPath: IndexPath)

    // MARK: FetchedResultsControllerDelegate
    @objc optional func dataSourceWillChangeContent(_ dataSource: DataSource)
    @objc optional func dataSource(_ dataSource: DataSource, didInsertRecord record: Record, atIndexPath indexPath: IndexPath)
    @objc optional func dataSource(_ dataSource: DataSource, didUpdateRecord record: Record, atIndexPath indexPath: IndexPath)
    @objc optional func dataSource(_ dataSource: DataSource, didDeleteRecord record: Record, atIndexPath indexPath: IndexPath)
    @objc optional func dataSource(_ dataSource: DataSource, didMoveRecord record: Record, fromIndexPath oldIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath)
    @objc optional func dataSourceDidChangeContent(_ dataSource: DataSource)

    // MARK: - Table View

    // MARK: Sections and Headers
    @objc optional func sectionIndexTitlesForDataSource(_ dataSource: DataSource, tableView: UITableView) -> [String]
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, titleForFooterInSection section: Int) -> String?
    @objc optional func dataSource(_ dataSource: DataSource, sectionIndexTitleForSectionName sectionName: String) -> String?

    // MARK: Editing
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, commitEditingStyle editingStyle: UITableViewCell.EditingStyle, forRowAtIndexPath indexPath: IndexPath)

    // MARK: Moving or Reordering
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func dataSource(_ dataSource: DataSource, tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath)

    // MARK: - UICollectionView
    @objc optional func dataSource(_ dataSource: DataSource, collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath, withTitle title: Any?) -> UICollectionReusableView?

}
