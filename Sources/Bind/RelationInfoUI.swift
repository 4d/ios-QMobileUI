//
//  RelationInfoUI.swift
//  QMobileUI
//
//  Created by phimage on 18/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileDataStore
import QMobileAPI // emptyable protocol

/// Protocol to provide info on relation
public protocol RelationInfoUI: NSObjectProtocol {
    /// Relation object data.
    var relation: Any? { get }
    /// The relation name
    var relationName: String? { get }
    /// The relation label
    var relationLabel: String? { get set }
    /// The relation short label
    var relationShortLabel: String? { get }
    /// The relation format
    var relationFormat: String? { get }
    /// The inverse relation name.
    // var inverseRelationName: String? { get } // CLEAN to remove
    /// Is relation to many.
    var relationIsToMany: Bool { get }
    /// Add action to launch segue.
    var addRelationSegueAction: Bool { get }

    /// Value displayed computed from other field and data
    var relationDisplayedValue: String? { get set }
    /// In case of miss configuration of template add something to show error
    func setRelationDisclosure()
    /// Add transition segue to go to relation form
    func addRelationSegue()
    /// Desactivate relation transition segue.
    func removeRelationSegue()
}

extension RelationInfoUI {

    var relationPreferredLongLabel: String? {
        return relationLabel.isEmpty ? relationShortLabel: relationLabel
    }
}

extension RelationInfoUI where Self: UIView {

    func checkRelationFormat() {
        if let relation = self.relation {
            if let record = relation as? RecordBase { // -> 1
                assert(!relationIsToMany)
                if let relationFormat = self.relationPreferredLongLabel,
                   !relationFormat.isEmpty,
                   let formatter = RecordFormatter(format: relationFormat, tableInfo: record.tableInfo) {
                    relationDisplayedValue = formatter.format(record)
                } else if let relationLabel = relationPreferredLongLabel {
                    relationDisplayedValue = relationLabel
                } else {
                    // button.setTitle("", for: .normal)
                }
            } else if let set = self.relation as? NSMutableSet { // -> N
                assert(relationIsToMany)
                if var relationLabel = relationPreferredLongLabel, !relationLabel.isEmpty {
                    relationLabel = relationLabel.replacingOccurrences(of: "%length%", with: String(set.count))
                    relationDisplayedValue = relationLabel
                } else {
                    // we have no label, no info
                    assertionFailure("Why relation label is empty? see storyboard metadata")
                    setRelationDisclosure()
                }
            } else {
                logger.warning("Unknown data type for relation \(relation)")
            }
            addRelationSegue()
        } else {
            if logger.isEnabledFor(level: .verbose) {
                logger.verbose("relation not yet data: \(relationIsToMany), \(Thread.callStackSymbols[6]) \(self)")
            }
            // If no data to bind, empty the widget (this is done one time before binding)
            if self.relationPreferredLongLabel.isEmpty, !self.relationDisplayedValue.isEmpty {
                relationLabel = self.relationDisplayedValue // here we try to get label from graphical component if there is no definition (could have reentrance)
                logger.debug("No relation label binding information in UDRA, so use \(String(describing: self.relationDisplayedValue))")
            }
            relationDisplayedValue = "" // empty data if no data from db
            removeRelationSegue()
        }
    }
}

struct RelationInfoUIAssociatedKeys {
    static var relation = "RelationInfoUI.relation"
    static var relationName = "RelationInfoUI.relationName"
    static var relationFormat = "RelationInfoUI.relationFormat"
    static var relationLabel = "RelationInfoUI.relationLabel"
    static var relationShortLabel = "RelationInfoUI.relationShortLabel"
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
    @objc dynamic open var relationShortLabel: String? {
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

    @objc dynamic open var relationShortLabel: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationShortLabel) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationShortLabel, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
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
    open var relationDisplayedValue: String? {
        get {
            return nil
        }
        set { // swiftlint:disable:this unused_setter_value
        }
    }

    open func setRelationDisclosure() {
    }

    open func addRelationSegue() {
    }

    open func removeRelationSegue() {
    }

}

extension UIView {

    func findRelationContainer(with segueIdentifier: String?) -> RelationContainerView? {
        // OPTI optimize that by stopping when found first
        return self.allSubviews.compactMap({$0 as? RelationContainerView}).filter({$0.relationName == segueIdentifier}).first
    }

}
