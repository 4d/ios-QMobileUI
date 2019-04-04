//
//  UISwipeAction+ActionUI.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 05/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import DeviceKit
import QMobileAPI

// MARK: - UITableView

extension UITableView: ActionSheetUI {

    // public typealias ActionUIItem = UIContextualAction
    public func actionUIType() -> ActionUI.Type {
        return UIContextualAction.self
    }
    public func addActionUI(_ item: ActionUI?) {
        /*if let action = item as? UIContextualAction {
            //contextualActions.append(action)
        }*/
    }

   /* private struct AssociatedKeys {
        static var contextualAction = "UITableView.UIContextualAction"
    }

    /// A list of context actions created from "actions" json.
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
     }*/

    public static var maxVisibleContextualActions: Int {
        let device: Device = .current
        if device.isPad {
            return 6
        }
        /*
         if case .landscape = device.orientation {
         return 4 // not working if the orientation change is not allowed on app
         }
         */
        return 3
    }

    fileprivate func gradientBackgroundColor(_ contextualActions: [UIContextualAction], color: UIColor? = UIColor(named: "BackgroundColor")) {
        if var color = color {
            for _ in contextualActions {
                color = color.lighter() ?? color
            }
            for contextualAction in contextualActions {
                if contextualAction.backgroundColor == UIContextualAction.defaultBackgroundColor {
                    contextualAction.backgroundColor = color
                }
                color = color.darker() ?? color
            }
        }
    }

    /// Create UISwipeActionsConfiguration from self 'contextualActions'
    /// with "more" menu item if more than `maxVisibleContextualActions` itemsb
    public func swipeActionsConfiguration(with context: ActionContext?, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let actionSheet = self.actionSheet else { return .empty }
        guard !actionSheet.actions.isEmpty else { return .empty /* no actions */}

        // To get current context, we rebuild the actions here, could not be done before if context could not be injected in handler
        var contextualActions = self.build(from: actionSheet, context: context ?? self, handler: ActionManager.instance.executeAction).compactMap { $0 as? UIContextualAction }

        guard contextualActions.count > UITableView.maxVisibleContextualActions else {
            gradientBackgroundColor(contextualActions)
            let configuration = UISwipeActionsConfiguration(actions: contextualActions)
            configuration.performsFirstActionWithFullSwipe = false
            return configuration
        }
        // swipe action more "..."
        contextualActions = contextualActions[0..<(UITableView.maxVisibleContextualActions-1)].array
        gradientBackgroundColor(contextualActions) // more not recolorized if here

        let moreItem = UIContextualAction(style: .normal, title: "More", handler: { (_, contextualView, handle) in
            let actions = actionSheet.actions
            let moreSheet = ActionSheet(title: nil,
                                        subtitle: nil,
                                        dismissLabel: "Cancel",
                                        actions: actions[UITableView.maxVisibleContextualActions-1..<actions.count].array)
            var alertController = UIAlertController.build(from: moreSheet, context: context ?? self, handler: ActionManager.instance.executeAction)
            alertController = alertController.checkPopUp(contextualView)
            alertController.show {
                handle(false) // to dismiss immediatly or in completion handler of alertController
            }
        })
        let oneHasImage = contextualActions.reduce(false) { result, contextualAction in
            return result || contextualAction.image != nil
        }
        if oneHasImage {
            moreItem.image = .moreImage
        }
        contextualActions.append(moreItem)

        let configuration = UISwipeActionsConfiguration(actions: contextualActions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension UIImage {
    /// More image from resource or use system one
    static let moreImage: UIImage? = UIImage(named: "tableMore") ?? UITabBarItem(tabBarSystemItem: UITabBarItem.SystemItem.more, tag: 3).image
}

extension UISwipeActionsConfiguration {

    static let empty = UISwipeActionsConfiguration(actions: [])
}

// MARK: - UIContextualAction

extension UIContextualAction: ActionUI {

    public static func build(from action: Action, parameters: ActionParameters?, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = UIContextualAction(
            style: UIContextualAction.Style.from(actionStyle: action.style),
            title: action.shortLabel ?? action.label ?? action.name) { (contextualAction, _ /* buttons view children of table view, not cell*/, handle) in
                handler(action, contextualAction, parameters)
                let success = false // if true and style = destructive, line will be removed...
                handle(success)
        }
        actionUI.image = ActionUIBuilder.actionImage(for: action)
        if let backgroundColor = ActionUIBuilder.actionColor(for: action) {
            actionUI.backgroundColor = backgroundColor
        }
        return actionUI
    }

    static var defaultBackgroundColor: UIColor! = UIContextualAction(style: .normal, title: nil, handler: { _, _, _ in

        }).backgroundColor

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
    public static func build(from action: Action, context: ActionUIContext, handler: @escaping ActionUI.Handler) -> ActionUI {
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
