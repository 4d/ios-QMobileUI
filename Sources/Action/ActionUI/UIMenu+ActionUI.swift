//
//  UIMenu+ActionUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 04/09/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

#if swift(>=5.1)
import QMobileAPI
import UIKit

@available(iOS 13.0, *)
extension UIMenu: ActionSheetUI {

    public func actionUIType() -> ActionUI.Type {
        return UIAction.self
    }

    public func addActionUI(_ item: ActionUI?) {}
}

@available(iOS 13.0, *)
extension UIAction: ActionUI {

    public static func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = UIAction(
            title: action.label ?? action.name,
            image: ActionUIBuilder.actionImage(for: action),
            identifier: nil,
            attributes: UIMenuElement.Attributes.from(actionStyle: action.style),
            state: .on) { actionUI in
                handler(action, actionUI, context)
        }
        return actionUI
    }
}

@available(iOS 13.0, *)
extension UIMenuElement.Attributes {
    static let empty: UIMenuElement.Attributes = []

    static func from(actionStyle: ActionStyle?) -> UIMenuElement.Attributes {
        guard let actionStyle = actionStyle else { return .empty }
        switch actionStyle {
        case .destructive:
            return .destructive
        case .normal:
            return empty
        case .custom: // hidden, disabled?
            return empty
        }
    }
}

#endif
