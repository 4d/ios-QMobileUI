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
    /// DataSource provide table as context.
    @objc public func actionContextParameters() -> ActionParameters? {
        return [ActionParametersKey.table: tableName]
    }
}

extension RecordDataSource/*: ActionContext*/ {
    /// DataSource provide table as context.
    @objc override public func actionContextParameters() -> ActionParameters? {
        guard var parameters = super.actionContextParameters() else {
            return nil
        }
        if let parentContext = self.formContext?.actionContext,
            let parentContextParameters = parentContext.actionContextParameters(),
            let record = parentContextParameters[ActionParametersKey.record] as? [String: Any] {

            var parent: [String: Any] = record
            if let relationName = self.formContext?.relationName {
                parent[ActionParametersKey.relationName] = relationName
            }
            if let relationName = self.formContext?.inverseRelationName {
                var entity: [String: Any] = parameters[ActionParametersKey.record] as? [String: Any] ?? [:]
                entity[ActionParametersKey.relationName] = relationName
                parameters[ActionParametersKey.record] = entity
            }
            parent[ActionParametersKey.table] = parentContextParameters[ActionParametersKey.table]
            parameters[ActionParametersKey.parent] = parent
        }

        return parameters
    }
}

extension DataSourceEntry: ActionContext {
    /// DataSourceEntry provide table and record primary key as context.
    public func actionContextParameters() -> ActionParameters? {
        var parameters = self.dataSource.actionContextParameters()
        if let record = self.record as? Record, let primaryKeyValue = record.primaryKeyValue {
            parameters?[ActionParametersKey.record] = [ActionParametersKey.primaryKey: primaryKeyValue]
        }
        return parameters
    }

    public func actionParameterValue(for field: String) -> Any? {
        if let record = self.record as? Record {
            return record.value(forKeyPath: field)
        }
        return nil
    }
}

extension DataSourceParentEntry: ActionContext {

    /// DataSourceParentEntry provide table and parent record primary key and its data class and also relationName  as context.
    public func actionContextParameters() -> ActionParameters? {
        guard var parameters = self.actionContext?.actionContextParameters() else {
            return nil
        }

        if let parentContext = self.formContext.actionContext,
            let parentContextParameters = parentContext.actionContextParameters(),
            let record = parentContextParameters[ActionParametersKey.record] as? [String: Any] {

            var parent: [String: Any] = record
            if let relationName = self.formContext.relationName {
                parent[ActionParametersKey.relationName] = relationName
            }
            if let relationName = self.formContext.inverseRelationName {
                var entity: [String: Any] = parameters[ActionParametersKey.record] as? [String: Any] ?? [:]
                entity[ActionParametersKey.relationName] = relationName
                parameters[ActionParametersKey.record] = entity
            }
            parent[ActionParametersKey.table] = parentContextParameters[ActionParametersKey.table]
            parameters[ActionParametersKey.parent] = parent
        }

        return parameters
    }

    public func actionParameterValue(for field: String) -> Any? {
        return self.actionContext?.actionParameterValue(for: field)
    }
}
