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
    // associatedtype ActionUIItem: ActionUI // XXX swift generic do not work well with objc dynamic and storyboards
    func actionUIType() -> ActionUI.Type

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI]
    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI?

    func addActionUI(_ item: ActionUI?)
}

public extension ActionSheetUI {

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI] {
        return actionSheet.actions.compactMap {
            return actionUIType().build(from: $0, context: context, handler: handler)
        }
    }

    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI? {
        return actionUIType().build(from: action, context: context, handler: handler)
    }

    func addActionUIs(_ items: [ActionUI]) {
        for item in items {
            addActionUI(item)
        }
    }
}
