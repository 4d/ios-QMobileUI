//
//  ActionContextProvider.swift
//  QMobileUI
//
//  Created by Eric Marchand on 08/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI

public protocol ActionParametersProvider {

    /// Provide context information for the action.
    func actionContext(action: Action, actionUI: ActionUI) -> ActionParameters?

}

struct ActionParametersProviderKey {
    static let table = "dataClass"
    static let record = "entity"
    static let primaryKey = "primaryKey"
}
