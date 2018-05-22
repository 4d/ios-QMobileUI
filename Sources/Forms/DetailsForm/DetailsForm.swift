//
//  DetailsFormController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

public protocol DetailsForm: class {

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
    public var dataSource: DataSource? {
        return self.view.table?.dataSource
    }

    public var indexPath: IndexPath? {
        return self.view.table?.indexPath
    }

    public var record: Record? {
        return self.view.record as? Record
    }

    public var tableName: String? {
        return self.view.table?.dataSource.tableName
    }

    // MARK: standards actions

    public func nextRecord() {
        if let table = self.view.table {
            if let newIndex = table.nextIndexPath {
                cancelImageDownloadTasks()
                table.indexPath = newIndex // update the view (if not done auto by seting the index)
                checkActions(table)
                onRecordChanged()
            }
        }
    }

    public func previousRecord() {
        if let table = self.view.table {
            if let newIndex = table.previousIndexPath {
                cancelImageDownloadTasks()
                table.indexPath = newIndex // update the view (if not done auto by setting the index)
                checkActions(table)
                onRecordChanged()
            }
        }
    }

    public func firstRecord() {
        if let table = self.view.table {
            cancelImageDownloadTasks()
            table.indexPath = IndexPath.firstRow // update the view (if not done auto by setting the index)
            checkActions(table)
            onRecordChanged()
        }
    }

    public func lastRecord() {
        if let table = self.view.table {
            cancelImageDownloadTasks()
            table.indexPath = table.lastIndexPath // check nullity?
            checkActions(table)
            onRecordChanged()
        }
    }

    func checkActions() {
        if let table = self.view.table {
            checkActions(table)
        } else {
            logger.warning("DetailsForm do not receive information from Listform. Maybe the 'indexPath' function on the UICollectionViewCell do not return the index path.")
            assertionFailure("No table set when loading")
        }
    }

    func checkActions(_ table: DataSourceEntry) {
        self.hasPreviousRecord = table.hasPrevious
        self.hasNextRecord = table.hasNext
    }

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

// MARK: transtion on self
extension DetailsForm {

    public func transitionOnSelf(duration: TimeInterval, options: UIViewAnimationOptions = [], changeViewContent: () -> Void) {
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
        self.record = view.record
    }
    func snapshotViewAdded(_ view: UIView) {
    }
}
