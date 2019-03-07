//
//  ActionUI.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 05/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

public protocol ActionUI {
    typealias Handler = (Action, ActionUI) -> Void
    static func build(from action: Action, handler: @escaping Handler) -> ActionUI
}

/// Builder class to force cast
struct ActionUIBuilder {
    static func build<T>(_ type: T.Type, from action: Action, handler: @escaping ActionUI.Handler) -> T? where T: ActionUI {
        return type.build(from: action, handler: handler) as? T
    }

    /// Provide an image for the passed action.
    static func actionImage(for action: Action) -> UIImage? {
        guard let icon = action.icon else {
            return nil
        }
        return UIImage(named: icon) // XXX maybe add prefix
    }

    /// Provide a color for the passed action.
    static func actionColor(for action: Action) -> UIColor? {
        return nil
    }
}

public protocol ActionSheetUI {
    //associatedtype ActionUIItem: ActionUI // XXX swift generic do not work well with objc dynamic and storyboards
    func actionUIType() -> ActionUI.Type

    func build(from actionSheet: ActionSheet, handler: @escaping ActionUI.Handler) -> [ActionUI]
    func build(from action: Action, handler: @escaping ActionUI.Handler) -> ActionUI?

    func addActionUI(_ item: ActionUI?)
}

public extension ActionSheetUI {

    func build(from actionSheet: ActionSheet, handler: @escaping ActionUI.Handler) -> [ActionUI] {
        return actionSheet.actions.compactMap {
            actionUIType().build(from: $0, handler: handler)
        }
    }

    func build(from action: Action, handler: @escaping ActionUI.Handler) -> ActionUI? {
        return actionUIType().build(from: action, handler: handler)
    }

    func addActionUIs(_ items: [ActionUI]) {
        for item in items {
            addActionUI(item)
        }
    }
}
