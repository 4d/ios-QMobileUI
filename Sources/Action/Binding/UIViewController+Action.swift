//
//  UIViewController+Action.swift
//  QMobileUI
//
//  Created by Eric Marchand on 11/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine

import QMobileAPI

/// Extends `UIView` to add actionSheet and action "user runtimes defined attributes" through storyboards.
extension UIViewController {

    fileprivate struct AssociatedKeys {
        static var actionSheetKey = "UIViewController.ActionSheet"

        static var bag = Set<AnyCancellable>()
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
    open var actionSheet: QMobileAPI.ActionSheet? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    #else
    open var actionSheet: QMobileAPI.ActionSheet? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionSheetKey) as? QMobileAPI.ActionSheet
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionSheetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let actionSheet = newValue {
                if let actionSheetUI = self as? ActionSheetUI {
                    /// Build and add
                    if let view = self.view {
                        let items = actionSheetUI.build(from: actionSheet, context: view, moreActions: nil, handler: ActionManager.instance.prepareAndExecuteAction)
                        actionSheetUI.addActionUIs(items)
                    }

                } else {
                    // default behaviour: if clicked create a ui alert controller on button
                    if self.navigationController?.navigationBar != nil {

                        let button = UIButton(type: .custom)
                        button.frame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32)) // XXX get correct size
                        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
                        button.actionSheet = actionSheet

                        let barButton = UIBarButtonItem(customView: button)
                        barButton.tag = 777
                        self.navigationItem.add(where: .right, item: barButton, at: 0)
                    } else {
                        logger.warning("Could not install automatically actions into \(self) because there is no navigation bar")
                    }
                }
            }
        }
    }

    func addEllipsisView() {
        guard let barButton = self.navigationItem.rightBarButtonItems?.first(where: { $0.tag == 777 }) else {
            return // no action
        }
        guard let button = barButton.customView as? UIButton else {
            assertionFailure("No button installed in tag 777")
            return
        }
        addEllipsisView(to: button)
    }
    func removeEllipsisView() {
        UIViewController.AssociatedKeys.bag.removeAll()

        guard let barButton = self.navigationItem.rightBarButtonItems?.first(where: { $0.tag == 777 }) else {
            return // no action
        }
        guard let button = barButton.customView as? UIButton else {
            assertionFailure("No button installed in tag 777")
            return
        }
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
    }

    func addEllipsisView(to button: UIButton) {
        let actionContext = LazyActionContext { [weak self] in
            return (self as? ActionContextProvider)?.actionContext() // use Lazy because context is not available yet in controller
        }
        guard let ellipsisView = createEllipsisView(button.size) else { return }
        let image = button.image(for: .normal)
        let instance = ActionManager.instance

        func updateAnimation() {
            let hasPendingRequest = actionContext.filter(instance.requests).contains(where: { !$0.state.isFinal })
            if hasPendingRequest {
                if ellipsisView.superview == nil {
                    button.addSubview(ellipsisView)
                    ellipsisView.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
                    ellipsisView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
                    ellipsisView.sizeToFit()
                    button.setImage(nil, for: .normal)
                }
            } else {
                ellipsisView.removeFromSuperview()
                button.setImage(image, for: .normal) // restore image
            }
        }
        DispatchQueue.main.async {
            updateAnimation()
            //  listen to change of number of request
            instance.objectWillChange.receiveOnForeground().sink { _ in
                updateAnimation()
            }.store(in: &UIViewController.AssociatedKeys.bag)
        }
    }

    #endif

    @objc func actionSheetGesture(_ recognizer: UIGestureRecognizer) {
        guard case recognizer.state = UIGestureRecognizer.State.ended else {
            return
        }
        if let actionSheet = self.actionSheet {
            if let view = self.view {
                var alertController = UIAlertController.build(from: actionSheet, context: view, handler: ActionManager.instance.prepareAndExecuteAction)
				alertController = alertController.checkPopUp(recognizer)
                alertController.show()
            }
        } else {
            logger.debug("Action pressed but not actionSheet information")
        }
    }
}

/// Create an animated ellipsis view.
func createEllipsisView(_ size: CGSize) -> UIView? {
    let ellipsis = Ellipsis(scale: .medium, color: Color(UIColor.foreground.cgColor))
        .frame(width: size.width, height: size.height, alignment: .center)
    let ellipsisVC = UIHostingController(rootView: ellipsis)
    ellipsisVC.view.backgroundColor = .clear
    guard let ellipsisView = ellipsisVC.view else { return nil }
    return ellipsisView
}

extension UIBarButtonItem {

    convenience init(customView: UIButton) {
        self.init()
        self.customView = customView
    }
}

private class LazyActionContext: ActionContext {
    var builder: (() -> ActionContext?)

    init(_ builder: @escaping (() -> ActionContext?)) {
        self.builder = builder
    }

    lazy var actionContext: ActionContext? = {
        return builder()
    }()

    func actionContextParameters() -> ActionParameters? {
        assert(actionContext != nil, "no action context setted before using it")
        return actionContext?.actionContextParameters()
    }

    func actionParameterValue(for field: String) -> Any? {
        assert(actionContext != nil, "no action context setted before using it to get parameter val")
        return actionContext?.actionParameterValue(for: field)
    }
}

extension UIViewController {

    @objc func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }
}
extension UIControl {

    func onMenuActionTriggered(menuHandler: @escaping (UIMenu) -> UIMenu) {
        self.addAction(UIAction(title: "", handler: { _ in
            ApplicationReachability.instance.refreshServerInfo {
                DispatchQueue.main.async { [weak self] in // if done before menu visible we have "while no context menu is visible. This won't do anything."
                    guard let contextMenuInteraction = self?.contextMenuInteraction else {
                        logger.warning("Cannot update menu for action")
                        return
                    }
                    contextMenuInteraction.updateVisibleMenu(menuHandler)
                }
            }
        }), for: .menuActionTriggered)
    }
}
