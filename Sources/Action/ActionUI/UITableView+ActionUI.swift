//
//  UISwipeAction+ActionUI.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 05/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

// MARK: - UITableView

extension UITableView: ActionSheetUI {

    // public typealias ActionUIItem = UIContextualAction
    public func actionUIType() -> ActionUI.Type {
        return UIContextualAction.self
    }
    public func addActionUI(_ item: ActionUI?) {
        if let action = item as? UIContextualAction {
            contextualActions.append(action)
        }
    }

    private struct AssociatedKeys {
        static var contextualAction = "UITableView.UIContextualAction"
    }

    open var contextualActions: [UIContextualAction] {
        get {
            var actions = objc_getAssociatedObject(self, &AssociatedKeys.contextualAction) as? [UIContextualAction]
            if actions == nil {
                actions = []
                objc_setAssociatedObject(self, &AssociatedKeys.contextualAction, actions, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return actions ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.contextualAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static let maxVisibleContextualActions = 3

    func swipeActionsConfiguration(for record: Any) -> UISwipeActionsConfiguration? {
        let tableView = self
        var contextualActions = tableView.contextualActions
        var configuration = UISwipeActionsConfiguration(actions: contextualActions)
        guard !contextualActions.isEmpty else { return configuration }

        configuration.performsFirstActionWithFullSwipe = false
        guard contextualActions.count > UITableView.maxVisibleContextualActions else { return configuration }

        // swipe action more "..."
        contextualActions = contextualActions[0..<(UITableView.maxVisibleContextualActions-1)].array
        let moreItem = UIContextualAction(style: .normal, title: "More", handler: { (_, _, handle) in
            // TODO pass record according to index... for a new handler

            guard let actions = tableView._actionSheet?.actions else { return }

            let moreSheet = ActionSheet(title: nil,
                                        subtitle: nil,
                                        dismissLabel: "Done",
                                        actions: actions[UITableView.maxVisibleContextualActions-1..<actions.count].array)
            let alertController = UIAlertController.build(from: moreSheet, view: self, handler: self.executeAction)
            alertController.show {
                handle(false) // to dismiss immediatly or in completion handler of alertController
            }
        })
        moreItem.image = UIImage(named: "tableMore")
        contextualActions.append(moreItem)

        configuration = UISwipeActionsConfiguration(actions: contextualActions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - UIContextualAction

extension UIContextualAction: ActionUI {
    public static func build(from action: Action, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = UIContextualAction(style: UIContextualAction.Style.from(actionStyle: action.style), title: action.label) { (contextualAction, _, handle) in
            handler(action, contextualAction, view)
            let success = false // if true and style = destructive, line will be removed...
            handle(success)
        }
        actionUI.image = ActionUIBuilder.actionImage(for: action)
        if let backgroundColor = ActionUIBuilder.actionColor(for: action) {
            actionUI.backgroundColor = backgroundColor
        }
        return actionUI
    }

}

extension UIContextualAction.Style {
    static func from(actionStyle: ActionStyle?) -> UIContextualAction.Style {
        guard let actionStyle = actionStyle else { return .normal }
        switch actionStyle {
        case .destructive:
            return .destructive
        default:
            return .normal
        }
    }
}

// MARK: - UITableViewRowAction
/*
extension UITableViewRowAction: ActionUI {
    public static func build(from action: Action, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = self.init(style: UITableViewRowAction.Style.from(actionStyle: action.style), title: action.label, handler: { (tableAction, _) in
            handler(action, tableAction, view)
        })
        if let backgroundColor = ActionUIBuilder.actionColor(for: action) {
            actionUI.backgroundColor = backgroundColor
        }
        return actionUI
    }
}

extension UITableViewRowAction.Style {
    static func from(actionStyle: ActionStyle?) -> UITableViewRowAction.Style {
        guard let actionStyle = actionStyle else { return .normal }
        switch actionStyle {
        case .destructive:
            return .destructive
        default:
            return .normal
        }
    }
}

// MARK: - UISwipeActionsConfiguration

 extension UISwipeActionsConfiguration: ActionSheetUI {

 // public typealias ActionUIItem = UIContextualAction
 public func actionUIType() -> ActionUI.Type {
 return UIContextualAction.self
 }
 public func addActionUI(_ item: ActionUI?) {
 // Not addable, must create a new object
 }
 convenience init?(actionSheet: ActionSheet, handler: @escaping ActionUI.Handler) {
 if actionSheet.actions.isEmpty {
 return nil
 }
 let builder = UISwipeActionsConfiguration(actions: [])
 let actions = builder.build(from: actionSheet, handler: handler)
 self.init(actions: actions.compactMap { $0 as? UIContextualAction })
 }
 }*/

fileprivate extension ArraySlice {
    var array: [Element] {
        return [Element](self)
    }
}
