//
//  RecordFormatter+QMobileDataStore.swift
//  QMobileUI
//
//  Created by Eric Marchand on 30/08/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileDataStore
import QMobileDataSync

extension RecordFormatter {

    /// Create a formatter only with allowed field using database info
    init?(format: String, tableInfo: DataStoreTableInfo) {
        self.init(format: format, fieldNodeInfo: DataStoreFieldNodeInfo(tableInfo: tableInfo))
    }
}

private struct DataStoreFieldNodeInfo: FieldNodeInfo {
    let tableInfo: DataStoreTableInfo
    func fieldName(name: String) -> String? {
        return tableInfo.fields.filter({ $0.originalName == name}).first?.name
    }
}
