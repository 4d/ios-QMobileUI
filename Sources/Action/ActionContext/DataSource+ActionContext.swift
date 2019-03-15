//
//  DataSource+ActionContext.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

extension DataSource: ActionContext {
    public func actionParameters(action: Action) -> ActionParameters? {
        return [ActionParametersKey.table: tableName]
    }
}
extension DataSourceEntry: ActionContext {
    public func actionParameters(action: Action) -> ActionParameters? {
        var parameters = self.dataSource.actionParameters(action: action)
        if let record = self.record as? Record, let primaryKeyValue = record.primaryKeyValue {
            parameters?[ActionParametersKey.record] = [ActionParametersKey.primaryKey: primaryKeyValue]
        }
        return parameters
    }
}
