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
            return self.actionSheet?.toJSON() ?? ""
        }
        set {
            actionSheet = ActionSheet.self.decode(fromJSON: newValue)
        }
    }

    #if TARGET_INTERFACE_BUILDER
    open var actionSheet: ActionSheet? {
        get { return nil }
        set {}
    }
    #else
    open var actionSheet: ActionSheet? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionSheetKey) as? ActionSheet
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionSheetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let actionSheet = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    /// Build and add
                    let items = actionSheetUI.build(from: actionSheet, context: self, handler: ActionManager.instance.executeAction)
                    actionSheetUI.addActionUIs(items)
                } else {
                    // default behaviour: if clicked create a ui alert controller
                    addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionSheetGesture(_:))))
                }
            }
        }
    }
    #endif

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let actionSheet = self.actionSheet {
            foreground {
                let alertController = UIAlertController.build(from: actionSheet, context: self, handler: ActionManager.instance.executeAction)
                alertController.show()
            }
        } else {
            logger.debug("Action pressed on \(self) but not actionSheet information")
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

    #if TARGET_INTERFACE_BUILDER
    open var _action: Action? { // swiftlint:disable:this identifier_name // use as internal like IBAnimatable
        get { return nil }
        set {}
    }
    #else
    open var _action: Action? { // swiftlint:disable:this identifier_name // use as internal like IBAnimatable
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? Action
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let action = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    if let actionUI = actionSheetUI.build(from: action, context: self, handler: ActionManager.instance.executeAction) {
                        actionSheetUI.addActionUI(actionUI)
                    }
                } else {
                    // default behaviour: if clicked create a ui alert controller
                    addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionGesture(_:))))
                }
            }
        }
    }
    #endif

    @objc func actionGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let action = self._action {
            // XXX execute the action or ask confirmation if only one action? maybe according to action definition

            let alertController = UIAlertController(title: action.label ?? action.name, message: "Confirm", preferredStyle: .alert)
            let item = alertController.build(from: action, context: self, handler: ActionManager.instance.executeAction)
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
        if self is UIViewCell {
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
