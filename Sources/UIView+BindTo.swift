//
//  UIView+BindTo.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

private var xoAssociationKey: UInt8 = 0
public typealias BindedRecord = AnyObject // XXX replace by Record?
public extension UIView {

    public var bindTo: Binder! {
        get {
            var bindTo = objc_getAssociatedObject(self, &xoAssociationKey) as? Binder
            if bindTo == nil { // XXX check multithread  safety
                bindTo = Binder(view: self)
                self.bindTo = bindTo
            }
            bindTo?.resetKeyPath()
            return bindTo
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var hasBindTo: Bool {
        let bindTo = objc_getAssociatedObject(self, &xoAssociationKey) as? Binder
        return bindTo != nil
    }

    // MARK: data
    public var record: BindedRecord? {
        get {
            return self.bindTo.record
        }
        set {
            self.bindTo.record = newValue
        }
    }

    public var hasRecord: Bool {
        if !hasBindTo {
            return false
        }
        return record != nil
    }

    public var table: DataSourceEntry? {
        get {
            return self.bindTo.table
        }
        set {
            self.bindTo.table = newValue
        }
    }
}

extension UIView {
    // Trying to avoid app crash if bad binding
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        logger.warning("Trying to set value '\(String(describing: value))' on key '\(key)' on view '\(self)")
    }

}

// MARK: view hierarchy
public extension UIView {

    public var recordView: UIView? {
        var currentView: UIView? = self
        while currentView?.superview != nil {
            currentView = currentView?.superview
            if currentView?.hasRecord ?? false {
                return currentView
            }
        }
        return nil
    }

}
