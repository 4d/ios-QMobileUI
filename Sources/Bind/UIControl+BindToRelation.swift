//
//  UIControl+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Protocol to provide info on relation
public protocol RelationInfoUI {
    /// Relation object data.
    var relation: Any? { get }
    /// The relation name
    var relationName: String? { get }
    /// The inverse relation name.
    var inverseRelationName: String? { get }
}

private var xoAssociationKey: UInt8 = 0
private var xoAssociationKey2: UInt8 = 0
private var xoAssociationKey3: UInt8 = 0

extension UIControl: RelationInfoUI {

    #if TARGET_INTERFACE_BUILDER
    @objc dynamic open var relation: Any? {
        return nil
    }
    #else
    @objc dynamic open var relation: Any? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey)
        }
        set {
            // self.isEnabled = newValue != nil // Feature deactivate button if no relations?
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    #endif

    #if TARGET_INTERFACE_BUILDER
    @objc dynamic open var relationName: String? {
        return nil
    }
    @objc dynamic open var inverseRelationName: String? {
        return nil
    }
    #else
    @objc dynamic open var relationName: String? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey2) as? String
        }
        set {
            objc_setAssociatedObject(self, &xoAssociationKey2, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    @objc dynamic open var inverseRelationName: String? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey3) as? String
        }
        set {
            objc_setAssociatedObject(self, &xoAssociationKey3, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    #endif
}
