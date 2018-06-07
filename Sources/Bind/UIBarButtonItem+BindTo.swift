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
extension UIBarItem {

    #if TARGET_INTERFACE_BUILDER
    open var bindTo: Binder {
        return Binder(binded: self)
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

    open override func value(forUndefinedKey key: String) -> Any? {
        return bindTo
    }

}
