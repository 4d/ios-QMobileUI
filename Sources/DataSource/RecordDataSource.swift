//
//  RecordDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/02/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

class RecordDataSource: DataSource {

    init?(record: RecordBase, dataStore: DataStore = DataStoreFactory.dataStore) {
        let tableInfo = record.tableInfo
        let tableName = tableInfo.name
        guard let firstField = tableInfo.fields.filter({$0.type.isSortable}).first else {
            return nil
        }
        let sortDescriptors: [NSSortDescriptor]  = [firstField.sortDescriptor(ascending: true)]

        var fetchRequest = dataStore.fetchRequest(tableName: tableName, sortDescriptors: sortDescriptors)
        fetchRequest.predicate = record.predicate

        let fetchedResultsController = dataStore.fetchedResultsController(fetchRequest: fetchRequest)
        try? fetchedResultsController.performFetch()
        super.init(fetchedResultsController: fetchedResultsController)
    }

}
