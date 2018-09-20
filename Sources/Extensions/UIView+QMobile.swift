//
//  UIView.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

// MARK: - View hierarcgy
public extension UIView {

    public var rootView: UIView? {
        var currentView: UIView? = self
        while currentView?.superview != nil {
            currentView = currentView?.superview
        }
        if let cell = currentView as? UIViewCell, let parentView = cell.parentView { // parentView could not be set already...
            return parentView.rootView
        }
        return currentView
    }

    public var parentCellView: UIViewCell? {
        var currentView: UIView? = self
        while currentView?.superview != nil {
            let parent = currentView?.superview
            if let cell = parent as? UIViewCell {
                return cell
            }
            currentView = parent
        }
        return nil
    }

    // break MVC paradigm, use it only for debug
    var viewController: UIViewController? {
        var next = self.superview
        while let safeNext = next {
            if let nextResponder = safeNext.next {
                if let responder = nextResponder as? UIViewController {
                    return responder
                }
            }
            next = safeNext.superview
        }
        return nil
    }

}

// MARK: - Frame
public extension UIView {

    // swiftlint:disable:next identifier_name
    public var x: CGFloat {
        get { return frame.x }
        set { frame = frame.with(x: newValue) }
    }

    // swiftlint:disable:next identifier_name
    public var y: CGFloat {
        get { return frame.y }
        set { frame = frame.with(y: newValue) }
    }

    public var width: CGFloat {
        get { return frame.width }
        set { frame = frame.with(width: newValue) }
    }

    public var height: CGFloat {
        get { return frame.height }
        set { frame = frame.with(height: newValue) }
    }
}

// MARK: animation delegate

extension UIView {

    public func shake(duration: CFTimeInterval = 0.6,
                      timingFunction: CAMediaTimingFunction = .linear,
                      completion: (() -> Void)? = nil) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = timingFunction
        animation.duration = duration
        animation.values = [ -20, 20, -20, 20, -10, 10, -5, 5, 0]
        if let completion = completion {
            animation.delegate = AnimationDelegate(completion: completion)
        }
        layer.add(animation, forKey: "shake")
    }

    public func shrink(duration: CFTimeInterval,
                       timingFunction: CAMediaTimingFunction = .linear,
                       completion: (() -> Void)? = nil) {
        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.fromValue = frame.width
        animation.toValue = frame.height
        animation.duration = duration
        animation.timingFunction = timingFunction
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        if let completion = completion {
            animation.delegate = AnimationDelegate(completion: completion)
        }
        layer.add(animation, forKey: "shrink")
    }

    public func expand(duration: CFTimeInterval = 0.3,
                       timingFunction: CAMediaTimingFunction = .linear,
                       completion: (() -> Void)? = nil) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 26.0
        animation.timingFunction = timingFunction
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        if let completion = completion {
            animation.delegate = AnimationDelegate(completion: completion)
        }
        layer.add(animation, forKey: "expand")
    }

}

// MARK: `CAAnimationDelegate`
open class AnimationDelegate: NSObject, CAAnimationDelegate {

    fileprivate let completion: () -> Void

    public init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    open func animationDidStop(_: CAAnimation, finished: Bool) {
        completion()
    }
}

extension CAMediaTimingFunction {
    public static let linear = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
}
