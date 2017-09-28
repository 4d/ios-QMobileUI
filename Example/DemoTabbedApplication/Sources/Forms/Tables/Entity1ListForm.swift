//
//  Entity1ListFormTable.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 10/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore
import IBAnimatable

/// Generated controller for Entity table.
/// Do not edit name or override tableName
class Entity1ListForm: ListFormTable {

    public override var tableName: String {
        return "Entity1"
    }
    @IBAction func testDataSyncOnButton(_ sender: Any) {

        /*_ = dataSync {_ in
         
         }*/

        _ = dataStore.perform(.background) { ( context, save) in
            do {
                if let table = self.table {
                    if try context.delete(in: table) {
                        print("ok delete \(table.name)")
                    } else {
                        print("nothing delete \(table.name)")
                    }
                }
                /* if let record = self.firstRecord {
                 context.delete(record: record)
                 */
                try save()
            } catch {
                logger.warning("Failed to delete record \(error)")
            }

        }

    }

    @IBAction override open func refresh(_ sender: Any?) {
        onRefreshBegin()

        let date: Date? = dataLastSync()  ?? Date() // remove default date
        if let date = date {

            self.refreshControl?.title = "Last sync "+DateFormatter.fullDate.string(from: date)
        } else {
            self.refreshControl?.title = ""
        }
        self.refreshControl?.tintColor = .white // DEMO
        let cancellable = dataSync { _ in

            self.refreshControl?.endRefreshing()
            self.onRefreshEnd()

        }

    }

}

extension UIRefreshControl {

    open var title: String? {
        get {
            return attributedTitle?.string
        }
        set {
            if let string = newValue {
                self.attributedTitle = NSAttributedString(string: string)
            } else {
                self.attributedTitle = nil
            }
        }
    }

}
