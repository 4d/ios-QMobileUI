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

    var formContext: FormContext?

    convenience init?(record: RecordBase, dataStore: DataStore = DataStoreFactory.dataStore) {
        self.init(tableInfo: record.tableInfo, predicate: record.predicate, dataStore: dataStore)
    }

    init?(tableInfo: DataStoreTableInfo, predicate: NSPredicate, dataStore: DataStore = DataStoreFactory.dataStore, context: DataStoreContext? = nil, fetchLimit: Int? = nil) {
        let tableName = tableInfo.name
        guard let firstField = tableInfo.fields.filter({$0.type.isSortable}).first else {
            return nil
        }
        let sortDescriptors: [NSSortDescriptor]  = [firstField.sortDescriptor(ascending: true)]

        var fetchRequest = dataStore.fetchRequest(tableName: tableName, sortDescriptors: sortDescriptors)
        fetchRequest.predicate = predicate
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }

        let fetchedResultsController = dataStore.fetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: nil, context: context)
        try? fetchedResultsController.performFetch()
        super.init(fetchedResultsController: fetchedResultsController)
    }

    override func beginUpdates() {
    }
    override func endUpdates() {
    }
    override func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
    }

}
