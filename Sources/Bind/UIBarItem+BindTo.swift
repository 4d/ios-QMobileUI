//
//  UIBarButtonItem+BindTo.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// An UIBarButtonItem is not a view, so binding information must be look in attached view

private var xoAssociationKey: UInt8 = 0
extension UIBarItem: Binded {

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
        return bindTo! //swiftlint:disable:this force_cast
    }
    #endif

    open override func value(forUndefinedKey key: String) -> Any? {
        return bindTo
    }

	public func setProperty(name: String, value: Any?) {
		self.setValue(value, forKey: name)
	}
	public func getPropertyValue(name: String) -> Any? {
		return value(forKey: name)
	}
	public var bindedRoot: Binded {
		return self // XXX must find navigation bar from hierarchy but not authorized...
	}
}
