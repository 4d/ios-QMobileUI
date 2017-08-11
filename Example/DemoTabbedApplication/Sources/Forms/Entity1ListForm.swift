//
//  Entity1ListFormTable.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 10/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

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
                        print("ok delete")
                    }
                }
                /* if let record = self.firstRecord {
                 context.delete(record: record)
                 */
                try save()
            } catch {
                loggerapp.warning("Failed to delete record \(error)")
            }

        }

    }

}
