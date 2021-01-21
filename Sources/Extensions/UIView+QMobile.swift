//
//  UIView.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

extension UIView {

    // MARK: frame
    var size: CGSize {
        get {
            return self.frame.size
        }
        set {
            self.width = newValue.width
            self.height = newValue.height
        }
    }

    var width: CGFloat {
        get { return self.frame.size.width
        }
        set { self.frame.size.width = newValue }
    }

    var height: CGFloat {
        get { return self.frame.size.height }
        set { self.frame.size.height = newValue }
    }

    var x: CGFloat { // swiftlint:disable:this identifier_name
        get { return frame.x }
        set { frame = frame.with(x: newValue) }
    }

    var y: CGFloat { // swiftlint:disable:this identifier_name
        get { return frame.y }
        set { frame = frame.with(y: newValue) }
    }

    // MARK: layer
    var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            layer.borderColor = color.cgColor
        }
    }

    var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
}

// MARK: - View hierarcgy
public extension UIView {

    var rootView: UIView? {
        var currentView: UIView? = self
        while currentView?.superview != nil {
            currentView = currentView?.superview
        }
        if let cell = currentView as? UIViewCell, let parentView = cell.parentView { // parentView could not be set already...
            return parentView.rootView
        }
        return currentView
    }

    var parentCellView: UIViewCell? {
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

    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subView in subviews {
            if let firstResponder = subView.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }

    var allSubviews: [UIView] {
        var result = self.subviews
        let subviews = result
        for subview in subviews {
            result += subview.allSubviews
        }
        return result
    }
}

protocol LayoutGuide {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}
extension UILayoutGuide: LayoutGuide {}
extension UIView: LayoutGuide {}

extension UIView {

    func snap(to guide: LayoutGuide) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            self.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            self.topAnchor.constraint(equalTo: guide.topAnchor),
            self.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
            ])
    }
}

extension UIResponder {
    // break MVC paradigm, use it only for debug if possible
    var owningViewController: UIViewController? {
        var nextResponser = self
        while let next = nextResponser.next {
            nextResponser = next
            if let viewController = nextResponser as? UIViewController {
                return viewController
            }
            if let view = nextResponser as? UIView {
                if let viewVC = view.owningViewController {
                    return viewVC
                }
            }
        }
        return nil
    }
}

// MARK: - Frame
/*
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

}*/

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
