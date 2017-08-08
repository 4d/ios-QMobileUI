//
//  UIBarButtonItem+BindTo.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// An UIBarButtonItem is not a view, so binding information must be look in attached view
private let kView = "vi" + "ew"
extension UIBarButtonItem {

    open var bindTo: Binder! {
        if let view = value(forKey: kView) as? UIView { // a button?
            /* view.rootView  // a bar? */
            return view.bindTo
        }
        logger.debug("UIBarButtonItem \(self) is not attached to a view. Maybe not visible. Cannot bind")
        return nil
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        return bindTo
    }

}
