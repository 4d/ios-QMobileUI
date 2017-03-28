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

    // swiftlint:disable variable_name
    public var x: CGFloat {
        get { return frame.x }
        set { frame = frame.with(x: newValue) }
    }

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
