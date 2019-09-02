//
//  DetailsFormController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileDataStore
import QMobileAPI

public protocol DetailsForm: class, ActionContextProvider, Form, Storyboardable {

    // the root view of form
    var view: UIView! {get set}

    /// @return: true if the is previous record
    var hasPreviousRecord: Bool {get set}
    /// @return: true if the is next record
    var hasNextRecord: Bool {get set}

    /// Called when record changed
    func onRecordChanged()

}

extension DetailsForm {

    // MARK: model info from DataSource

    /// The source where to retrieve record information.
    var entry: DataSourceEntry? {
        return view.table
    }

    /// The source where to retrieve record information.
    public var dataSource: DataSource? {
        return entry?.dataSource
    }

    /// Table name of the data source. (same as `dataSource?.tableName`)
    public var tableName: String? {
        return dataSource?.tableName
    }

    /// Current index of the record in `dataSource`
    public var indexPath: IndexPath? {
        return entry?.indexPath
    }

    fileprivate var _record: Record? { // swiftlint:disable:this identifier_name
        return entry?.record as? Record
    }

    var tableInfo: DataStoreTableInfo? {
        return _record?.tableInfo
    }

    /// The record in `dataSource` at the `indexPath`
    public var record: AnyObject? {
        return _record?.store // CLEAN, not really clean to use wrapper
    }

    public var recordID: CVarArg? {
        return _record?.store.objectID
    }

    /// Get the primary key value of record.
    fileprivate var recordKey: Any? {
        guard let record = self._record else {
            return nil
        }
        return record.primaryKeyValue
    }

    // MARK: standards actions

    /// Go to the next record in data source if any.
    public func nextRecord() {
        guard let table = self.view.table, let newIndex = table.nextIndexPath else { return }
        cancelImageDownloadTasks()
        table.indexPath = newIndex // update the view (if not done auto by seting the index)

        checkActions(table)
        onRecordChanged()
    }

    /// Return to the previous record in data source if any.
    public func previousRecord() {
        guard let table = self.view.table, let newIndex = table.previousIndexPath else { return }
        cancelImageDownloadTasks()
        table.indexPath = newIndex // update the view (if not done auto by setting the index)
        checkActions(table)
        onRecordChanged()
    }

    /// Go to the first record in data source.
    public func firstRecord() {
        if let table = self.view.table {
            cancelImageDownloadTasks()
            table.indexPath = IndexPath.firstRow // update the view (if not done auto by setting the index)
            checkActions(table)
            onRecordChanged()
        }
    }

    /// Go to the last record in data source.
    public func lastRecord() {
        if let table = self.view.table {
            cancelImageDownloadTasks()
            table.indexPath = table.lastIndexPath // check nullity?
            checkActions(table)
            onRecordChanged()
        }
    }

    public func updateViews() {
        self.view?.bindTo.updateView()
    }

    // check if action must be enabled or not.
    func checkActions() {
        guard let table = self.view.table else {
            logger.warning("DetailsForm do not receive information from Listform. Maybe the 'indexPath' function on the UICollectionViewCell do not return the index path.")
            assertionFailure("No table set when loading")
            return
        }
        checkActions(table)
    }

    func checkActions(_ table: DataSourceEntry) {
        self.hasPreviousRecord = table.hasPrevious
        self.hasNextRecord = table.hasNext
    }

    // try to stop all image download task.
    func cancelImageDownloadTasks() {
        let imageViews: [UIImageView] = filter(value: view) { $0.subviews }
        for imageView in imageViews {
            imageView.kf.cancelDownloadTask()
        }
    }

    /*public*/func deleteRecord() {
        if let table = self.view.table {
            if let record = table.record?.record as? Record {
                let dataStore = DataStoreFactory.dataStore // must use same in dataSync
                _ = dataStore.perform(.background, blockName: "deleteRecord") { context in
                    context.delete(record: record)

                    try? context.commit()
                }
            } else {
                logger.warning("Failed to get selected record for deletion")
            }
        }
    }

}
// MARK: - transtion on self

extension DetailsForm {

    public func transitionOnSelf(duration: TimeInterval, options: UIView.AnimationOptions = [], changeViewContent: () -> Void) {
        var initialView: UIView?
        if self.view is TransitionContainerViewType {
            initialView = self.view?.subviews.first
        } else {
            /*if let view = self.view {
                let container = TransitionContainerView()
                self.view = container
                container.addSubview(view)
                container.viewAdded(view)
                initialView = view
            }*/
        }

        if let initialView = initialView,
            let snapshotView = initialView.snapshotView(afterScreenUpdates: false),
            let container = self.view as? TransitionContainerViewType {
            self.view?.addSubview(snapshotView)
            container.snapshotViewAdded(view)
            changeViewContent()
            UIView.transition(from: snapshotView, to: initialView, duration: 1, options: options) { _ in
                snapshotView.removeFromSuperview()
                // Could add here a call to a completionHandler
            }
        } else {
            changeViewContent()
        }
    }

}

public protocol TransitionContainerViewType {
    func viewAdded(_ view: UIView)
    func snapshotViewAdded(_ view: UIView)
}

class TransitionContainerView: UIView, TransitionContainerViewType {

    func viewAdded(_ view: UIView) {
        self.table = view.table
    }
    func snapshotViewAdded(_ view: UIView) {
    }
}

// MARK: - ActionContextProvider

extension DetailsForm {

    public func actionContext() -> ActionContext? {
        return self.view.table
    }

}
