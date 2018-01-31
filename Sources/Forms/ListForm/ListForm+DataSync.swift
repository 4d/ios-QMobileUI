//
//  ListForm+DataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI
import QMobileDataSync

extension ListForm {

    public var table: Table? {
        assert(!ApplicationDataSync.dataSync.tablesInfoByTable.isEmpty) // not loaded...

        let dataSync = ApplicationDataSync.dataSync
        return dataSync.tables.filter { $0.name == self.tableName }.first
    }

}
