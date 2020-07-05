//
//  UILabel+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 05/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation

extension UILabel: RelationInfoUI {

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
    /*@objc dynamic open var inverseRelationName: String? {
     get { return nil }
     set {} // swiftlint:disable:this unused_setter_value
     }*/
    @objc dynamic open var addRelationSegueAction: Bool {
        get { return false }
        set {} // swiftlint:disable:this unused_setter_value
    }
    #else
    @objc dynamic open var relation: Any? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relation)
        }
        set {
            // self.isEnabled = newValue != nil // Feature deactivate button if no relations?
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

            if addRelationSegueAction { // to deactivate set addRelationSegueAction before relationName
                self.isUserInteractionEnabled = true
                let gestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(self.relationTapped(_:)))
                self.addGestureRecognizer(gestureRecognizer)
                self.textColor = .relationLink
            }
        }
    }

    @objc open func relationTapped(_ sender: UITapGestureRecognizer) {
        guard let currentViewController = self.owningViewController else { // break MVC paradigm...
            logger.warning("Failing to get controller of label \(self)")
            return
        }
        guard let relationName = self.relationName else {
            return
        }
        // TODO BUG do not transition if not possible, ie for instance no date for this relation
        // only solution ask currentViewController to do the job?, same a performSegue code
        currentViewController.performSegue(withIdentifier: relationName, sender: self)
    }
    #endif
}

extension UIColor {
    /// Color for relatio link. Use "relationLink" asset name to define it or use .link
    static var relationLink: UIColor = {
        return UIColor(named: "relationLink") ?? .link
    }()
}
