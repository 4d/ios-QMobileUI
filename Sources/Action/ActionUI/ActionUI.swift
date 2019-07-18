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

    typealias Handler = (Action, ActionUI, ActionContext) -> Void

    /// Build an action ui element.
    static func build(from action: Action, context: ActionContext, handler: @escaping Handler) -> ActionUI
}

/// Builder class to force cast
public struct ActionUIBuilder {
    public static func build<T>(_ type: T.Type, from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> T? where T: ActionUI {
        return type.build(from: action, context: context, handler: handler) as? T
    }

    /// Provide an image for the passed action.
    public static func actionImage(for action: Action) -> UIImage? {
        guard let icon = action.icon else {
            return nil
        }
        return UIImage(named: icon)
    }

    /// Provide a color for the passed action.
    public static func actionColor(for action: Action) -> UIColor? {
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
