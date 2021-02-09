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
extension UIView: Binded {

	// MARK: - Binded
    #if TARGET_INTERFACE_BUILDER
    @objc dynamic open var bindTo: Binder {
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
        // swiftlint:disable:next force_cast
        return bindTo!
    }
    #endif

    @objc dynamic open var hasBindTo: Bool {
        let bindTo = objc_getAssociatedObject(self, &xoAssociationKey) as? Binder
        return bindTo != nil
    }

	public func setProperty(name: String, value: Any?) {
        let oldValue: Any? = getPropertyValue(name: name)
        var newValue = value
        if let oldValue = oldValue, oldValue is Bool, value == nil {
            newValue = false
        }
		self.setValue(newValue, forKey: name)
	}

	public func getPropertyValue(name: String) -> Any? {
		// add some mapping
		switch name {
		case "root": return rootView
		case "cell": return parentCellView
		default: return value(forKey: name)
		}
	}

	public var bindedRoot: Binded {
		// what we want : if dynamic table, the cellview must be selected, otherwise the root view. And root view must not be a cell..

		// CLEAN here a tricky way to select cellview or rootview, very very dirty code
		// maybe we could check table type, or add a protocol or a boolean(at creation, not runtime) to a view to select it
		if let cellView = self.parentCellView {
			if cellView.parentViewSource is DataSource { // List form, keep cell data
				if let binded = cellView as? Binded {
					return binded
				}
			}
			if let rootView = self.rootView {
				return rootView
			}
			if let binded = cellView as? Binded {
				return binded
			}
		}

		if let rootView = self.rootView {
			return rootView
		}
		return self
	}

    // MARK: - data

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

    var recordView: UIView? {
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
