//
//  DetailsForm+DataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI
import QMobileDataSync

extension DetailsForm {

    public var table: Table? {
        guard let tableName = self.tableName else {
            return nil
        }
        let dataSync = ApplicationDataSync._instance.dataSync
        assert(!dataSync.tablesInfoByTable.isEmpty) // not loaded...
        return dataSync.tables.filter { $0.name == tableName }.first
    }

}
