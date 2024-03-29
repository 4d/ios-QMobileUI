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
        return UIMenuElement.self
    }

    public func addActionUI(_ item: ActionUI?) {}
}

@available(iOS 13.0, *)
extension UIMenuElement: ActionUI {

    public static func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = UIAction(
            title: action.preferredLongLabel,
            image: ActionUIBuilder.actionImage(for: action)?.withRenderingMode(.alwaysTemplate),
            identifier: UIAction.Identifier(rawValue: action.name),
            attributes: UIMenuElement.Attributes.from(actionStyle: action.style)) { actionUI in
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

extension UIMenu {
    static func build(from actionSheet: ActionSheet, context: ActionContext, moreActions: [ActionUI]?, handler: @escaping ActionUI.Handler) -> UIMenu {
        let more = (moreActions ?? [])
        let menuItem = actionSheet.actions.compactMap { UIMenuElement.build(from: $0, context: context, handler: handler) as? UIMenuElement } + more.compactMap({ $0 as? UIMenuElement})
        // XXX maybe force destructive mode if one menu item has destructive
        return UIMenu(title: actionSheet.title ?? "", image: nil, identifier: nil, options: [], children: menuItem)
    }
}

#endif
