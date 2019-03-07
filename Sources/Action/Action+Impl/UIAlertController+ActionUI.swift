//
//  UIAlertController+Action.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 28/02/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

extension UIAlertAction: ActionUI {
    public static func build(from action: Action, handler: @escaping ActionUI.Handler) -> ActionUI {
        let actionUI = self.init(title: action.label, style: UIAlertAction.Style.from(actionStyle: action.style)) { alertAction in
            handler(action, alertAction)
        }
        if let image = ActionUIBuilder.actionImage(for: action) {
            actionUI.setValue(image, forKey: "image")
        }
        if let backgroundColor = ActionUIBuilder.actionColor(for: action) {
            actionUI.setValue(backgroundColor, forKey: "titleTextColor")
        }
        return actionUI
    }
}

extension UIAlertAction.Style {
    static func from(actionStyle: ActionStyle?) -> UIAlertAction.Style {
        guard let actionStyle = actionStyle else { return .default }
        switch actionStyle {
        case .destructive: return .destructive
        case .normal: return .default
        }
    }
}

extension UIAlertController: ActionSheetUI {

    // public typealias ActionUIItem = UIAlertAction
    public func actionUIType() -> ActionUI.Type {
        return UIAlertAction.self
    }

    public func addActionUI(_ item: ActionUI?) {
        if let item = item as? UIAlertAction {
            self.addAction(item)
        }
    }
}

extension UIAlertController {
    static func build(from actionSheet: ActionSheet, handler: @escaping ActionUI.Handler) -> UIAlertController {
        let alertController = UIAlertController(title: actionSheet.title, message: actionSheet.subtitle, preferredStyle: .actionSheet)
        let items = alertController.build(from: actionSheet, handler: handler)
        alertController.addActionUIs(items)
        alertController.addAction(alertController.cancelAction(title: actionSheet.dismissLabel ?? "Cancel"))
        return alertController
    }
}
