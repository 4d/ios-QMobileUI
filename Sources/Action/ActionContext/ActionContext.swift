//
//  ActionContext.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

/// An action context provide parameters for action.
public protocol ActionContext {

    /// Provide parameters for the action.
    func actionParameters(action: Action) -> ActionParameters?

    /// Provide value for a field.
    func actionParameterValue(for field: String) -> Any?

}

public extension ActionContext {

    func actionParameterValue(for field: String) -> Any? {
        return nil
    }
}

/// Protocol to define class which could provide `ActionContext`
public protocol ActionContextProvider {

    func actionContext() -> ActionContext?
}

/// Some well known key for ActionParameters (not public yet)
struct ActionParametersKey {
    static let table = "dataClass"
    static let record = "entity"
    static let primaryKey = "primaryKey"
}

extension ActionParameter {

    public func defaultValue(with context: ActionContext) -> Any? {
        if let value = self.default {
            return value
        }
        if let field = self.defaultField {
            return context.actionParameterValue(for: field)
        }
        return nil // TODO compute default value according to a defined properties and context
    }
}
