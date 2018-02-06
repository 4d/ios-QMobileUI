//
//  ListForm+DataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI
import QMobileDataStore
import QMobileDataSync

extension ListForm {

    /// Return information about current table using 4D table and field naming
    public var table: Table? {
        let dataSync = ApplicationDataSync.dataSync
        assert(!dataSync.tablesInfoByTable.isEmpty) // not loaded...

        for (table, tableInfo) in dataSync.tablesInfoByTable where tableInfo.name == self.tableName {
            return table
        }
        return nil
    }

    /// Return information about current table using mobile database table and field naming
    public var tableInfo: DataStoreTableInfo? {
        let dataSync = ApplicationDataSync.dataSync
        assert(!dataSync.tablesInfoByTable.isEmpty) // not loaded...

        for (_, tableInfo) in dataSync.tablesInfoByTable where tableInfo.name == self.tableName {
            return tableInfo
        }
        return nil
    }
}
