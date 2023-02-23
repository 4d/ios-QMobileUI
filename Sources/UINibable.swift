//
//  UINibable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Protocol for UI element associated with an interface
public protocol UINibable {
    /// The name of the nib to be loaded to instantiate the view.
    var nibName: String? { get }
    /// The bundle from which to load the nib.
    var nibBundle: Bundle? { get }
}

extension UINibable {

    /// Create an `UINib` using the `nibName` and `nibBundle`
    public var nib: UINib? {
        guard let nibName = self.nibName else {
            return nil
        }
        return UINib(nibName: nibName, bundle: nibBundle)
    }

    public var nibBundle: Bundle? {
        return nil // by default
    }

}

extension UINibable where Self: UIView {
    public var nibName: String? {
        return self.className
    }
}

extension UIViewController: UINibable {
    /*public var nibBundle: Bundle? {
        return Bundle(for: type(of:self))
    }*/
}

extension UINibable {

    public func registerHeaderFooter(to tableView: UITableView, reuseIdentifier: String) {
        if let nib = self.nib {
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
    }
}

extension UITableView {
    // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
    public func dequeueReusableCell<T: ReusableView>(_: T.Type) -> T? {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T
    }

    // like dequeueReusableCellWithIdentifier:, but for headers/footers
    public func dequeueReusableHeaderFooterView<T: ReusableView>(_: T.Type) -> T? {
        return dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T
    }

    // Instances returned from the new dequeue method will also be properly sized when they are returned.

    public func registerCell<T: ReusableView>(_ nib: UINib?, for: T.Type) {
        self.register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }

    public func registerHeaderFooter<T: ReusableView>(_ nib: UINib?, for: T.Type) {
        self.register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    public func registerHeaderFooter<T>(_ view: T) where T: ReusableView, T: UINibable {
        if let nib = view.nib {
            self.register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        }
    }
}

public protocol ReusableView {
    static var reuseIdentifier: String { get }
}

public extension ReusableView {
    static var reuseIdentifier: String {
        let className = String(describing: self)
        return "\(className)"
    }
}
