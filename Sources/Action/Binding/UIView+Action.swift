//
//  Action+Binding.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 04/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

/// Extends `UIView` to add actionSheet and action "user runtimes defined attributes" through storyboards.
extension UIView {

    private struct AssociatedKeys {
        static var actionSheetKey = "UIView.ActionSheet"
        static var actionKey = "UIView.Action"
    }
    // MARK: - ActionSheet

    /// Binded action sheet string.
    @objc dynamic var actions: String {
        get {
            return self._actionSheet?.toJSON() ?? ""
        }
        set {
            _actionSheet = ActionSheet.self.decode(fromJSON: newValue)
        }
    }

    open var _actionSheet: ActionSheet? { // swiftlint:disable:this identifier_name // use as internal like IBAnimtable
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionSheetKey) as? ActionSheet
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionSheetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let actionSheet = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    /// Build and add
                    let items = actionSheetUI.build(from: actionSheet, context: self, handler: ActionUIManager.executeAction)
                    actionSheetUI.addActionUIs(items)

                } else {
                    // default behaviour: if clicked create a ui alert controller
                    addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionSheetGesture(_:))))
                }
            }
        }
    }

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let actionSheet = self._actionSheet {
            let alertController = UIAlertController.build(from: actionSheet, context: self, handler: ActionUIManager.executeAction)
            alertController.show()
        } else {
            logger.debug("Action pressed but not actionSheet information")
        }
    }

    // MARK: - Action
    /// Binded action string.
    @objc dynamic var action: String {
        get {
            return self._action?.toJSON() ?? ""
        }
        set {
            _action = Action.self.decode(fromJSON: newValue)
        }
    }

    open var _action: Action? { // swiftlint:disable:this identifier_name // use as internal like IBAnimatable
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? Action
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let action = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    if let actionUI = actionSheetUI.build(from: action, context: self, handler: ActionUIManager.executeAction) {
                        actionSheetUI.addActionUI(actionUI)
                    }
                } else {
                    // default behaviour: if clicked create a ui alert controller
                    addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionGesture(_:))))
                }
            }
        }
    }

    @objc func actionGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let action = self._action {
            // XXX execute the action or ask confirmation if only one action? maybe according to action definition

            let alertController = UIAlertController(title: action.label, message: "Confirm", preferredStyle: .alert)
            let item = alertController.build(from: action, context: self, handler: ActionUIManager.executeAction)
            alertController.addActionUI(item)
            alertController.addAction(alertController.dismissAction())
            alertController.show()
        } else {
            logger.debug("Action pressed but not action information")
        }
    }

    // MARK: - Common

    /// Create a gesture recognizer with specified action.
    func createActionGestureRecognizer(_ action: Selector?) -> UIGestureRecognizer {
        if self is UITableViewCell { // bad practice! to cast in lower class, but cannot override in extension, maybe add a protocol to defined type of gesture
            return UILongPressGestureRecognizer(target: self, action: action)
        } else {
            return UITapGestureRecognizer(target: self, action: action)
        }
    }

}

// MARK: - UIBarItem
extension UIBarItem {

    // bind action on bar item if there is a view (button) used with it.
    @objc dynamic var actions: String {
        get {
            return (self.value(forKey: "view") as? UIView)?.actions ?? ""
        }
        set {
            (self.value(forKey: "view") as? UIView)?.actions = newValue
        }
    }

    // cannot bind with action. UIBarButtonItem have "action: Selector" (or rename action)

}

// MARK: - ActionParametersProvider

/// Protocol to define class which could provide `ActionParameters`
public protocol ActionContextUIContext: ActionContext {

}

/// Some well known key for ActionParameters (not public yet)
struct ActionParametersProviderKey {
    static let table = "dataClass"
    static let record = "entity"
    static let primaryKey = "primaryKey"
}

// MARK: - ActionUIContext

extension UIView: ActionContext {

    public func actionParameters(action: Action, actionUI: ActionUI) -> ActionParameters? {
        var parameters: ActionParameters = ActionParameters()

        if let provider = self.findActionUIContext(action, actionUI) {
            parameters = provider.actionParameters(action: action, actionUI: actionUI) ?? [:]
        }
        return parameters
    }

    fileprivate func findActionUIContext(_ action: Action, _ actionUI: ActionUI) -> ActionContextUIContext? {
        /// view hierarchical search if current view do not provide the context
        if let provider = self as? ActionContextUIContext {
            return provider
        }
        // view hierarchy recursion
        if let provider = self.superview?.findActionUIContext(action, actionUI) {
            return provider
        }

        // specific case for table and collection view cell which break the view hierarchy
        if let provider = self.parentCellView?.parentView?.findActionUIContext(action, actionUI) { /// XXX maybe do it only at first level to optimize
            return provider
        }

        // in final resort, the current view controller
        if let provider = self.owningViewController as? ActionContextUIContext {
            return provider
        }
        return nil
    }
}
