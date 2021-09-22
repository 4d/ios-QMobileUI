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
        if name.contains(".") {
            var coreDataNames: [String] = []
            var keyPath = name.split(separator: ".")
            guard let last = keyPath.popLast() else {
                logger.verbose("Cannot find in database \(name) from \(tableInfo.name)")
                return nil
            }
            var keyTable: DataStoreTableInfo? = tableInfo
            for key in keyPath {
                guard let relation = keyTable?.relationships.first(where: { $0.originalName == key}) else {
                    logger.debug("Cannot find in database \(name) from \(tableInfo.name), when looking for relation \(key)")
                    return nil
                }
                coreDataNames.append(relation.name)
                keyTable = relation.destinationTable
            }
            guard let field = keyTable?.fields.first(where: { $0.originalName == last}) else {
                logger.debug("Cannot find in database \(name) from \(tableInfo.name), when looking for field \(last) into \(keyTable?.name ?? "")")
                return nil
            }
            coreDataNames.append(field.name)
            return coreDataNames.joined(separator: ".")
        }
        return tableInfo.fields.first(where: { $0.originalName == name})?.name
    }
}
