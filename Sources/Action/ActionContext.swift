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
