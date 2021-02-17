//
//  Action+Binding.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 04/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

import Prephirences
import IBAnimatable

import QMobileAPI

/// Extends `UIView` to add actionSheet and action "user runtimes defined attributes" through storyboards.
extension UIView {

    private struct AssociatedKeys {
        static var actionIndex = "UIView.ActionIndex"
        static var actionSheetKey = "UIView.ActionSheet"
        static var actionKey = "UIView.Action"
        static var actionTouchKey = "UIView.ActionTouch"
    }
    // MARK: - ActionSheet

    /// Binded action sheet string.
    @objc dynamic var actions: String {
        get {
            return self.actionSheet?.toJSON() ?? ""
        }
        set {
            actionSheet = ActionSheet.self.decode(fromJSON: newValue)
            if self is UIControl {
                self.isHidden = actionSheet == nil // if no action,
            }
        }
    }

    #if TARGET_INTERFACE_BUILDER
    open var actionSheet: QMobileAPI.ActionSheet? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    open var actionIndex: NSNumber? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    #else
    @objc
    open var actionIndex: NSNumber? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionIndex) as? NSNumber
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    open var actionSheet: QMobileAPI.ActionSheet? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionSheetKey) as? QMobileAPI.ActionSheet
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionSheetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let actionSheet = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    /// Build and add
                    let items = actionSheetUI.build(from: actionSheet, context: self, moreActions: nil, handler: ActionManager.instance.prepareAndExecuteAction)
                    actionSheetUI.addActionUIs(items)
                } else {
                    let actionContext: ActionContext = self

                    if let actionIndex = actionIndex, actionSheet.actions[safe: actionIndex.intValue] != nil {
                        addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionGesture(_:))))
                        return
                    }
                    if let button = self as? UIButton, ActionFormSettings.useMenu {

                        let actionUI = UIAction(
                            title: "Actions log",
                            image: UIImage(systemName: "ellipsis"),
                            identifier: UIAction.Identifier(rawValue: "action.log"),
                            attributes: []) { actionUI in
                            let view = ActionRequestFormUI(requests: ActionManager.instance.requests, actionContext: actionContext)
                            let hostController = UIHostingController(rootView: view.environmentObject(ActionManager.instance))
                            let presentedController = UINavigationController(rootViewController: hostController)
                            presentedController.navigationBar.tintColor = UIColor.foreground
                            presentedController.navigationBar.isTranslucent = false
                            presentedController.navigationBar.barTintColor = UIColor.background
                            hostController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: hostController, action: #selector(hostController.dismissAnimated))
                            (self.owningViewController ?? UIApplication.topViewController)?.present(presentedController, animated: true, completion: {
                                logger.debug("present action more")
                            })
                        }

                        let deferredMenuElement = UIDeferredMenuElement { (elementProvider) in
                            /*if !ActionManager.instance.requests.filter({ !$0.state.isFinal }).isEmpty {*/ // not called at each display, there is a cache, we cannot update it
                            elementProvider([actionUI])
                        }

                        let menu = UIMenu.build(from: actionSheet, context: actionContext, moreActions: [deferredMenuElement], handler: ActionManager.instance.prepareAndExecuteAction)
                        button.menu = menu
                        button.showsMenuAsPrimaryAction = true
                    } else {
                        // default behaviour: if clicked create a ui alert controller
                        addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionSheetGesture(_:))))
                    }
                }
            }
        }
    }
    #endif

    fileprivate func showActionSheet(_ recognizer: UIGestureRecognizer) {
        if let actionSheet = self.actionSheet {
            var actionContext: ActionContext = self
            foreground {
                if let cell = self as? UIViewCell {
                    let cellIndexPath = cell.indexPath
                    if cellIndexPath != self.bindTo.table?.indexPath {
                        self.bindTo.table?.indexPath = cellIndexPath
                        logger.warning("Cell no more binding good index \(String(describing: cellIndexPath)) != \(String(describing: cellIndexPath))")
                    }
                    let viewController = cell.parentView?.findViewController()
                    if let listForm = viewController as? ListForm,
                       let formContext = listForm.formContext { // Success, there is a parent
                        actionContext = DataSourceParentEntry(actionContext: self, formContext: formContext)
                    }
                }
                var alertController: UIAlertController?
                alertController = .build(from: actionSheet, context: actionContext, handler: ActionManager.instance.prepareAndExecuteAction)
                alertController = alertController?.checkPopUp(recognizer)
                alertController?.show()
            }
        } else {
            logger.debug("Action pressed on \(self) but not actionSheet information")
        }
    }

    fileprivate func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        let isLongPress = recognizer is UILongPressGestureRecognizer

        if isLongPress && (touch.zoomScale != 1) {
            switch recognizer.state {
            case .began:
                self.touch.transform = self.transform
                UIView.animate(withDuration: touch.duration,
                               delay: touch.delay,
                               usingSpringWithDamping: touch.damping,
                               initialSpringVelocity: touch.velocity,
                               options: .curveEaseInOut,
                               animations: {
                                self.transform = .scaledBy(x: self.touch.zoomScale, y: self.touch.zoomScale)
                }, completion: nil)

                self.touch.timer = Timer.schedule(delay: touch.duration) { [weak self] timer in
                    guard let timer = timer, timer.isValid else { return }

                    if self?.touch.impact ?? false {
                        UIImpactFeedbackGenerator().impactOccurred()
                    }
                    self?.showActionSheet(recognizer)
                }
            case .cancelled, .ended, .failed:
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.transform = self.touch.transform
                }, completion: nil)
                self.touch.timer?.invalidate()
            case .possible, .changed:
                break
            @unknown default:
                 break
            }
        } else {
            // For long press recognizer we treat `.began` state as "active"
            let expectedState: UIGestureRecognizer.State = isLongPress ? .began : .ended
            guard case recognizer.state = expectedState else { return }
            showActionSheet(recognizer)
        }
    }

    @objc dynamic open var touch: ActionTouchConfiguration {
        get {
            if let configuration = objc_getAssociatedObject(self, &AssociatedKeys.actionTouchKey) as? ActionTouchConfiguration {
                return configuration
            }
            let configuration = ActionTouchConfiguration()
            if self is UIViewCell {
                configuration.gestureKind = .long
            }
            objc_setAssociatedObject(self, &AssociatedKeys.actionTouchKey, configuration, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return configuration
        }
        set(configuration) {
            objc_setAssociatedObject(self, &AssociatedKeys.actionTouchKey, configuration, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
        set {} // swiftlint:disable:this unused_setter_value
    }
    #else
    open var _action: Action? { // swiftlint:disable:this identifier_name // use as internal like IBAnimatable
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? Action
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue != nil {
                addGestureRecognizer(createActionGestureRecognizer(#selector(self.actionGesture(_:))))
            }
        }
    }
    #endif

    @objc func actionGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        let actionContext: ActionContext = self
        if let actionSheet = self.actionSheet, let actionIndex = self.actionIndex, let action = actionSheet.actions[safe: actionIndex.intValue] {
            ActionManager.instance.prepareAndExecuteAction(action, self as? ActionUI ?? BackgroundActionUI(), actionContext)
        } else if let action = self._action {
            ActionManager.instance.prepareAndExecuteAction(action, self as? ActionUI ?? BackgroundActionUI(), actionContext)
        } else {
            logger.debug("Action pressed but not action information")
        }
    }

    // MARK: - Common

    /// Create a gesture recognizer with specified action.
    func createActionGestureRecognizer(_ action: Selector?) -> UIGestureRecognizer {
        let recognizer = touch.gestureKind.gestureRecognizer(target: self, action: action)
        if let recognizer = recognizer as? UILongPressGestureRecognizer {
            if touch.zoomScale != 1 {
                recognizer.minimumPressDuration = 0.10 // immediate to launch animation
                recognizer.delaysTouchesBegan = false
            } else {
                recognizer.minimumPressDuration = touch.duration
            }
            if Int.max != touch.numberOfTapsRequired { // cannot use optional for objc and binding
                recognizer.numberOfTapsRequired = touch.numberOfTapsRequired
            }
            if Int.max != touch.numberOfTouchesRequired {
                recognizer.numberOfTouchesRequired = touch.numberOfTouchesRequired
            }
        } else if let recognizer = recognizer as? UITapGestureRecognizer {
            if Int.max != touch.numberOfTapsRequired {
                recognizer.numberOfTapsRequired = touch.numberOfTapsRequired
            }
            if Int.max != touch.numberOfTouchesRequired {
                recognizer.numberOfTouchesRequired = touch.numberOfTouchesRequired
            }
        } else if let recognizer = recognizer as? UISwipeGestureRecognizer {
            if Int.max != touch.numberOfTouchesRequired {
                recognizer.numberOfTouchesRequired = touch.numberOfTouchesRequired
            }
            recognizer.direction = touch._direction.swipeDirection
        } // else ...
        return recognizer
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

// MARK: - UIGestureRecognizer

extension UIGestureRecognizer.State: CustomStringConvertible {

    public var description: String {
        switch self {
        case .possible: return "possible"
        case .began: return "began"
        case .ended: return "ended"
        case .failed: return "failed"
        case .changed: return "changed"
        case .cancelled: return "cancelled"
        @unknown default: return "unknown"
        }
    }
}

extension UIGestureRecognizer {

    public enum Kind: String {
        case long, tap, swipe, pan, pinch, screenEdgePan, rotation
        static let `default`: Kind = .tap
    }

}

extension UIGestureRecognizer.Kind {

    func gestureRecognizer(target: Any? = nil, action: Selector? = nil) -> UIGestureRecognizer {
        switch self {
        case .long:
            return UILongPressGestureRecognizer(target: target, action: action)
        case .tap:
            return UITapGestureRecognizer(target: target, action: action)
        case .pan:
            return UIPanGestureRecognizer(target: target, action: action)
        case .swipe:
            return UISwipeGestureRecognizer(target: target, action: action)
        case .pinch:
            return UIPinchGestureRecognizer(target: target, action: action)
        case .screenEdgePan:
            return UIScreenEdgePanGestureRecognizer(target: target, action: action)
        case .rotation:
            return UIRotationGestureRecognizer(target: target, action: action)
        }
    }

}

// MARK: - configuration of action

/// Configure using user defined runtimes attributes touch gesture and animations.
public class ActionTouchConfiguration: NSObject {

    /// timer that could be used to launch the action
    public var timer: Timer?
    public var transform: CGAffineTransform = .identity

    // MARK: gesture
    @objc public var gesture: String = "" {
        didSet {
            guard let kind = UIGestureRecognizer.Kind(rawValue: gesture) else { return }
            gestureKind = kind
        }
    }
    public var gestureKind: UIGestureRecognizer.Kind = .default
    @objc public var numberOfTapsRequired: Int = Int.max
    @objc public var numberOfTouchesRequired: Int = Int.max
    @objc public var direction: String = "" {
        didSet {
            guard let direction = AnimationType.Direction(rawValue: direction) else { return }
            _direction = direction
        }
    }
    public var _direction: AnimationType.Direction = .up // swiftlint:disable:this identifier_name
    /// impact
    @objc public var impact: Bool = Prephirences.sharedInstance["action.cell.impact"] as? Bool ?? true

    // MARK: animation
    /// Zoom scale on cell view when doing long press. (Default: 1 , deactivated)
    @objc public var zoomScale: CGFloat = Prephirences.sharedInstance["action.cell.zoomScale"] as? CGFloat ?? 1
    @objc public var damping: CGFloat = 0.5
    @objc public var velocity: CGFloat = 5
    /// miminim press duration
    @objc public var duration: TimeInterval = Prephirences.sharedInstance["action.cell.minimumPressDuration"] as? Double ?? 1
    @objc public var delay: TimeInterval = 0
    @objc public var timingFunction: String = "" {
        didSet {
            _timingFunction =  TimingFunctionType(string: timingFunction)
        }
    }
    public var _timingFunction: TimingFunctionType = .default // swiftlint:disable:this identifier_name

}

extension AnimationType.Direction {

    var swipeDirection: UISwipeGestureRecognizer.Direction {
        switch self {
        case .down: return .down
        case .up: return .up
        case .left: return .left
        case .right: return .right
        }
    }
}
