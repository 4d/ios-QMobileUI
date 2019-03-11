//
//  UIViewController+Action.swift
//  QMobileUI
//
//  Created by Eric Marchand on 11/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

/// Extends `UIView` to add actionSheet and action "user runtimes defined attributes" through storyboards.
extension UIViewController {

    private struct AssociatedKeys {
        static var actionSheetKey = "UIViewController.ActionSheet"
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
                    if let view = self.view {
                        let items = actionSheetUI.build(from: actionSheet, view: view, handler: view.executeAction)
                        actionSheetUI.addActionUIs(items)
                    }

                } else {
                    // TODO do real code, not only add a touch on root view: create a button?

                    // XXX toremove = default behaviour: if clicked create a ui alert controller
                    if let view = self.view {
                        addGestureRecognizer(view.createActionGestureRecognizer(#selector(self.actionSheetGesture(_:))))
                    }
                }
            }
        }
    }

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let actionSheet = self._actionSheet {
            if let view = self.view {
                let alertController = UIAlertController.build(from: actionSheet, view: view, handler: view.executeAction)
                alertController.show()
            }
        } else {
            logger.debug("Action pressed but not actionSheet information")
        }
    }
}
