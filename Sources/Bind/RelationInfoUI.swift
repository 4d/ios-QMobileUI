//
//  RelationInfoUI.swift
//  QMobileUI
//
//  Created by phimage on 18/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Protocol to provide info on relation
public protocol RelationInfoUI {
    /// Relation object data.
    var relation: Any? { get }
    /// The relation name
    var relationName: String? { get }
    /// The relation format
    var relationFormat: String? { get }
    /// The inverse relation name.
    // var inverseRelationName: String? { get } // CLEAN to remove
    /// Is relation to many.
    var relationIsToMany: Bool { get }
    /// Add action to launch segue.
    var addRelationSegueAction: Bool { get }
}

struct RelationInfoUIAssociatedKeys {
    static var relation = "RelationInfoUI.relation"
    static var relationName = "RelationInfoUI.relationName"
    static var relationFormat = "RelationInfoUI.relationFormat"
    static var relationLabel = "RelationInfoUI.relationLabel"
    static var relationIsToMany = "RelationInfoUI.relationIsToMany"
    // static var inverseRelationName = "RelationInfoUI.inverseRelationName"
    static var addRelationSegueAction = "RelationInfoUI.addRelationSegueAction"
    static var relationTapGesture = "RelationInfoUI.relationTapGesture"
}

/// just a normal view wich implement `RelationInfoUI`
open class RelationContainerView: UIView, RelationInfoUI {

    #if TARGET_INTERFACE_BUILDER
    // To prevent storyboard issue with xcode do less using storyboard
    @objc dynamic open var relation: Any? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    @objc dynamic open var relationName: String? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    @objc dynamic open var relationFormat: String? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    @objc dynamic open var relationLabel: String? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    @objc dynamic open var relationIsToMany: Bool {
        get { return false }
        set {} // swiftlint:disable:this unused_setter_value
    }
    /*@objc dynamic open var inverseRelationName: String? {
     get { return nil }
     set {} // swiftlint:disable:this unused_setter_value
     }*/
    @objc dynamic open var addRelationSegueAction: Bool {
        get { return false }
        set {} // swiftlint:disable:this unused_setter_value
    }
    @objc dynamic open var relationTapGesture: UITapGestureRecognizer? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }

    #else
    @objc dynamic open var relation: Any? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relation)
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relation, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc dynamic open var relationFormat: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc dynamic open var relationLabel: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationLabel) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationLabel, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)

        }
    }

    @objc dynamic open var relationIsToMany: Bool {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationIsToMany) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationIsToMany, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)

        }
    }

    @objc dynamic open var relationTapGesture: UITapGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationTapGesture) as? UITapGestureRecognizer
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationTapGesture, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc dynamic open var addRelationSegueAction: Bool {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.addRelationSegueAction) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.addRelationSegueAction, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc public var relationName: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    #endif

}

extension UIView {

    func findRelationContainer(with segueIdentifier: String?) -> RelationContainerView? {
        // OPTI optimize that by stopping when found first
        return self.allSubviews.compactMap({$0 as? RelationContainerView}).filter({$0.relationName == segueIdentifier}).first
    }

}
