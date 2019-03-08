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
    @objc dynamic var actionSheet: String {
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
                    let items = actionSheetUI.build(from: actionSheet, view: self, handler: self.executeAction)
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
            let alertController = UIAlertController.build(from: actionSheet, view: self, handler: self.executeAction)
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
                    if let actionUI = actionSheetUI.build(from: action, view: self, handler: self.executeAction) {
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
            let item = alertController.build(from: action, view: self, handler: self.executeAction)
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

    /// Execute the action
    func executeAction(_ action: Action, _ actionUI: ActionUI, _ view: ActionUI.View) {
        // TODO get parameters for network actions
        let parameters: ActionParameters = ActionParameters()

        // execute the network action
        _ = APIManager.instance.action(action, parameters: parameters) { (result) in
            // Display result or do some actions (incremental etc...)
            switch result {
            case .failure(let error):
                print("\(error)")
                let alertController = UIAlertController(title: action.label, message: "\(error)", preferredStyle: .alert)
                alertController.addAction(alertController.dismissAction(title: "Done"))
            case .success(let value):
                print("\(value)")
                let alertController = UIAlertController(title: action.label, message: "\(value)", preferredStyle: .alert)
                alertController.addAction(alertController.dismissAction(title: "Done"))
            }
        }
    }

}

// MARK: - UIBarItem
extension UIBarItem {

    // bind action on bar item if there is a view (button) used with it.
    @objc dynamic var actionSheet: String {
        get {
            return (self.value(forKey: "view") as? UIView)?.actionSheet ?? ""
        }
        set {
            (self.value(forKey: "view") as? UIView)?.actionSheet = newValue
        }
    }

    // cannot bind with action. UIBarButtonItem have "action: Selector" (or rename action)

}
