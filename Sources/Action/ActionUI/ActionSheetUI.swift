//
//  ActionSheetUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/04/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

public protocol ActionSheetUI {
    //associatedtype ActionUIItem: ActionUI // XXX swift generic do not work well with objc dynamic and storyboards
    func actionUIType() -> ActionUI.Type

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI]
    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI?

    func addActionUI(_ item: ActionUI?)
}

public extension ActionSheetUI {

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI] {
        return actionSheet.actions.compactMap {
            let parameters = context.actionParameters(action: $0) // OPTI, if we remove unused action for build parameters, we could build only one time parameters
            return actionUIType().build(from: $0, parameters: parameters, handler: handler)
        }
    }

    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI? {
        let parameters = context.actionParameters(action: action)
        return actionUIType().build(from: action, parameters: parameters, handler: handler)
    }

    func addActionUIs(_ items: [ActionUI]) {
        for item in items {
            addActionUI(item)
        }
    }
}
