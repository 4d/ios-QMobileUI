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
        assert(!ApplicationDataSync.dataSync.tablesByName.isEmpty) // not loaded...
        guard let tableName = self.tableName else {
            return nil
        }
        return ApplicationDataSync.dataSync.tablesByName[tableName]
    }

}
