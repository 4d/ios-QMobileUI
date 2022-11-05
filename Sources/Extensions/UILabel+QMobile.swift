//
//  UILabel+QMobile.swift
//  QMobileUI
//
//  Created by emarchand on 26/10/2022.
//  Copyright © 2022 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

public extension UILabel {

    // MARK: - AssociatedObject
    private struct AssociatedKeys {
        static var isCopyingEnabled = "isCopyingEnabled"
        static var longPressGestureRecognizer = "longPressGestureRecognizer"
    }

    @IBInspectable var isCopyingEnabled: Bool {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.isCopyingEnabled)
            return (value as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isCopyingEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
            setupLongGestureRecognizer()
        }
    }

    @objc var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer) as? UILongPressGestureRecognizer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - UIResponder
    @objc
    override var canBecomeFirstResponder: Bool {
        return isCopyingEnabled
    }

    @objc
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(self.copy(_:)) && isCopyingEnabled)
    }

    @objc
    override func copy(_ sender: Any?) {
        if isCopyingEnabled {
            UIPasteboard.general.string = text
        }
    }

    // MARK: - long pressure menu
    @objc internal func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer === longPressGestureRecognizer && gestureRecognizer.state == .began {
            becomeFirstResponder()
            let copyMenu = UIMenuController.shared
            copyMenu.arrowDirection = .default
            copyMenu.showMenu(from: self, rect: bounds)
        }
    }

    fileprivate func setupLongGestureRecognizer() {
        if let gestureRecognizer = longPressGestureRecognizer {
            removeGestureRecognizer(gestureRecognizer)
            longPressGestureRecognizer = nil
        }

        if isCopyingEnabled {
            isUserInteractionEnabled = true
            let gestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(longPressGestureRecognized(gestureRecognizer:)))
            longPressGestureRecognizer = gestureRecognizer
            addGestureRecognizer(gestureRecognizer)
        }
    }
}
