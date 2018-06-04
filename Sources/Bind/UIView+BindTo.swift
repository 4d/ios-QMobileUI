//
//  UIView+BindTo.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import Prephirences

private var xoAssociationKey: UInt8 = 0
public typealias BindedRecord = AnyObject // XXX replace by Record?
extension UIView {

    #if TARGET_INTERFACE_BUILDER
    open var bindTo: Binder {
        return Binder(view: self)
    }
    #else
    @objc dynamic open var bindTo: Binder {
        var bindTo = objc_getAssociatedObject(self, &xoAssociationKey) as? Binder
        if bindTo == nil { // XXX check multithread  safety
            bindTo = Binder(view: self)
            objc_setAssociatedObject(self, &xoAssociationKey, bindTo, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        bindTo?.resetKeyPath()
        //swiftlint:disable:next force_cast
        return bindTo!
    }
    #endif

    @objc dynamic open var hasBindTo: Bool {
        let bindTo = objc_getAssociatedObject(self, &xoAssociationKey) as? Binder
        return bindTo != nil
    }

    // MARK: data

    open var settings: PreferencesType? {
        get {
            return Prephirences.sharedInstance
        }
        set {
            if let pref = newValue {
                Prephirences.sharedInstance = pref
            }
        }
    }

    @objc dynamic open var hasRecord: Bool {
        if !hasBindTo {
            return false
        }
        return bindTo.record != nil
    }

    open var table: DataSourceEntry? {
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
        #if !TARGET_INTERFACE_BUILDER
            if key.isEmpty {
                logger.debug("Trying to set value '\(String(unwrappedDescrib: value))' on empty key on view '\(self). View not binded. Please edit storyboard.")
            } else {
                logger.warning("Trying to set value '\(String(unwrappedDescrib: value))' on undefined key '\(key)' on view '\(self)")
            }
        #endif
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
