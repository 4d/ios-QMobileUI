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
import Prephirences

/// Extends `UIView` to add actionSheet and action "user runtimes defined attributes" through storyboards.
extension UIView {

    /// miminim press duration
    static let actionMinimumLongPressDuration: TimeInterval = Prephirences.sharedInstance["action.cell.minimumPressDuration"] as? Double ?? 1

    /// Zoom scale on cell view when doing long press. (Default: 1 , deactivated)
    static let actionLongPressZoomScale: CGFloat = Prephirences.sharedInstance["action.cell.zoomScale"] as? CGFloat ?? 1

    /// impact
    static let actionImpact: Bool = Prephirences.sharedInstance["action.cell.impact"] as? Bool ?? true

    private struct AssociatedKeys {
        static var actionSheetKey = "UIView.ActionSheet"
        static var actionKey = "UIView.Action"
        static var actionTimerKey = "UIView.ActionTimer"
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

    fileprivate func showActionSheet() {
        if let actionSheet = self.actionSheet {

            foreground {
                let alertController: UIAlertController = .build(from: actionSheet, context: self, handler: ActionManager.instance.executeAction)
                alertController.show()
            }
        } else {
            logger.debug("Action pressed on \(self) but not actionSheet information")
        }
    }

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        let isLongPress = recognizer is UILongPressGestureRecognizer

        if isLongPress && (UIView.actionLongPressZoomScale != 1) {
            switch recognizer.state {
            case .began:
                UIView.animate(withDuration: UIView.actionMinimumLongPressDuration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: {
                     self.transform = .scaledBy(x: UIView.actionLongPressZoomScale, y: UIView.actionLongPressZoomScale)
                }, completion: nil)

                self.actionTimer = Timer.schedule(delay: UIView.actionMinimumLongPressDuration) { [weak self] timer in
                    guard let timer = timer, timer.isValid else { return }

                    if UIView.actionImpact {
                        UIImpactFeedbackGenerator().impactOccurred()
                    }
                    self?.showActionSheet()
                }
            case .cancelled, .ended, .failed:
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                }, completion: nil)
                self.actionTimer?.invalidate()
            case .possible, .changed:
                break
            }
        } else {
            // For long press recognizer we treat `.began` state as "active"
            let expectedState: UIGestureRecognizer.State = isLongPress ? .began : .ended
            guard case recognizer.state = expectedState else { return }
            showActionSheet()
        }
    }

    open var actionTimer: Timer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionTimerKey) as? Timer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
            let recognizer = UILongPressGestureRecognizer(target: self, action: action)
            if UIView.actionLongPressZoomScale != 1 {
                recognizer.minimumPressDuration = 0
            } else {
                recognizer.minimumPressDuration = UIView.actionMinimumLongPressDuration
            }
            return recognizer
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

extension CGAffineTransform {

    public static func scaledBy(x sx: CGFloat, y sy: CGFloat) -> CGAffineTransform { // swiftlint:disable:this identifier_name
        return identity.scaledBy(x: sx, y: sy)
    }
}

extension UIGestureRecognizer.State: CustomStringConvertible {

    public var description: String {
        switch self {
        case .possible: return "possible"
        case .began: return "began"
        case .ended: return "ended"
        case .failed: return "failed"
        case .changed: return "changed"
        case .cancelled: return "cancelled"
        }
    }
}
