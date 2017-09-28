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
        assert(!ApplicationDataSync.dataSync.tablesByName.isEmpty) // not loaded...
        return ApplicationDataSync.dataSync.tablesByName[self.tableName]
    }

}
