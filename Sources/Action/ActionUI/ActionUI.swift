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

/// An action ui element could be builded from action and context and on action launch the passed handler.
public protocol ActionUI {

    typealias Handler = (Action, ActionUI, ActionParameters?) -> Void

    /// Build an action ui element.
    static func build(from action: Action, parameters: ActionParameters?, handler: @escaping Handler) -> ActionUI
}

/// Builder class to force cast
struct ActionUIBuilder {
    static func build<T>(_ type: T.Type, from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> T? where T: ActionUI {
        let parameters = context.actionParameters(action: action)
        return type.build(from: action, parameters: parameters, handler: handler) as? T
    }

    /// Provide an image for the passed action.
    static func actionImage(for action: Action) -> UIImage? {
        guard let icon = action.icon else {
            return nil
        }
        return UIImage(named: icon)
    }

    /// Provide a color for the passed action.
    static func actionColor(for action: Action) -> UIColor? {
        let defaultColor: UIColor? = nil
        guard let style = action.style else {
            return defaultColor
        }
        switch style {
        case .custom(let properties):
            if let color = properties["color"] as? String {
                return UIColor(named: color)
            }
        default:
            break
        }
        return defaultColor
    }
}
