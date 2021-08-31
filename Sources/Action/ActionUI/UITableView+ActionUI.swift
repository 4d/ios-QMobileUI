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
        /*if let action = item as? UIContextualAction {
            //contextualActions.append(action)
        }*/
    }

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

    fileprivate func gradientBackgroundColor(_ contextualActions: [UIContextualAction], color: UIColor? = UIColor.background) {
        if var color = color {
            let brightness = color.brightness
            let percentage: CGFloat = brightness < 0.5 ? 10 : 4
            for contextualAction in contextualActions.reversed() {
                if contextualAction.backgroundColor == UIContextualAction.defaultBackgroundColor {
                    contextualAction.backgroundColor = color
                }
                if brightness > 0.8 {
                    color = color.darker(by: percentage) ?? color
                } else {
                    color = color.lighter(by: percentage) ?? color
                }
            }
        }
    }

    /// Create `UISwipeActionsConfiguration` from action on table row
    /// with "more" menu item if more than `maxVisibleContextualActions` items
    public func swipeActionsConfiguration(with context: ActionContext, at indexPath: IndexPath) -> UISwipeActionsConfiguration {
        guard let contextualActions = self.swipeActions(with: context, at: indexPath) else {
            return .empty
        }
        let configuration = UISwipeActionsConfiguration(actions: contextualActions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    /// Create contextual actions from `actionSheet`
    /// with "more" menu item if more than `maxVisibleContextualActions` items
    public func swipeActions(with context: ActionContext, at indexPath: IndexPath, withMore: Bool = true) -> [UIContextualAction]? {
        // Get actions data
        guard let actionSheet = self.actionSheet, !actionSheet.actions.isEmpty else { return nil }

        // To get current context, we rebuild the actions here, could not be done before if context could not be injected in handler
        var contextualActions = self.build(from: actionSheet, context: context, moreActions: nil, handler: ActionManager.instance.prepareAndExecuteAction).compactMap { $0 as? UIContextualAction }

        // Check if we need more "..." action
        if withMore && contextualActions.count > UITableView.maxVisibleContextualActions {
            contextualActions = contextualActions[0..<(UITableView.maxVisibleContextualActions-1)].array

            let moreItem = UIContextualAction(style: .normal, title: "More", handler: { (_, contextualView, handle) in
                let actions = actionSheet.actions
                let moreSheet = ActionSheet(title: nil,
                                            subtitle: nil,
                                            dismissLabel: "Cancel",
                                            actions: actions[UITableView.maxVisibleContextualActions-1..<actions.count].array)
                var alertController = UIAlertController.build(from: moreSheet, context: context, handler: ActionManager.instance.prepareAndExecuteAction)
                alertController = alertController.checkPopUp(contextualView)
                alertController.show {
                    handle(false) // to dismiss immediatly or in completion handler of alertController
                }
            })
            // if one action has image, put also an image on more button
            if contextualActions.contains(where: { $0.image != nil }) {
                moreItem.image = .moreImage
            }
            contextualActions.append(moreItem)
        }
        gradientBackgroundColor(contextualActions)
        return contextualActions
    }
}

extension UIImage {
    /// More image from resource or use system one
    static let moreImage: UIImage? = UIImage(named: "tableMore") ?? UIImage(systemName: "ellipsis")
}

extension UISwipeActionsConfiguration {

    static let empty = UISwipeActionsConfiguration(actions: [])
}

// MARK: - UIContextualAction

extension UIContextualAction: ActionUI {

    public static func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI {

        let actionUI = UIContextualAction(
            style: UIContextualAction.Style.from(actionStyle: action.style),
            title: action.preferredShortLabel) { (contextualAction, _ /* buttons view children of table view, not cell*/, handle) in
                handler(action, contextualAction, context)
                let success = false // if true and style = destructive, line will be removed...
                handle(success)
        }
        if var image = ActionUIBuilder.actionImage(for: action) {
            if image.renderingMode != .alwaysOriginal {
                image = image.withRenderingMode(.alwaysTemplate)
            }
            actionUI.image = image
        }

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
