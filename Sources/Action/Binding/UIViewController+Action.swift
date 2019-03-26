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
                    if let view = self.view {
                        let items = actionSheetUI.build(from: actionSheet, context: view, handler: ActionManager.instance.executeAction)
                        actionSheetUI.addActionUIs(items)
                    }

                } else {
                    // default behaviour: if clicked create a ui alert controller on button
                    if self.navigationController?.navigationBar != nil {
                        let button = UIButton(type: .custom)
                        button.frame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32)) // XXX get correct size
                        button.setImage(.moreImage, for: .normal)

                        button.actionSheet = actionSheet // XXX button will be used as context by massing it. Maybe pass current controller as context...

                        let barButton = UIBarButtonItem(customView: button)
                        self.navigationItem.add(where: .right, item: barButton, at: 0)
                    } else {
                        logger.warning("Could not install automatically actions into \(self) because there is no navigation bar")
                    }
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
            if let view = self.view {
                var alertController = UIAlertController.build(from: actionSheet, context: view, handler: ActionManager.instance.executeAction)
				alertController = alertController.checkPopUp(recognizer)
                alertController.show()
            }
        } else {
            logger.debug("Action pressed but not actionSheet information")
        }
    }
}

extension UIBarButtonItem {

    convenience init(customView: UIButton) {
        self.init()
        self.customView = customView
    }
}
