//
//  UIControl+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileDataStore // TODO break dependences?; instance of ?

/// Protocol to provide info on relation
public protocol RelationInfoUI {
    /// Relation object data.
    var relation: Any? { get }
    /// The relation name
    var relationName: String? { get }
    /// The relation format
    var relationFormat: String? { get }
    /// The inverse relation name.
    //var inverseRelationName: String? { get } // CLEAN to remove

    /// Add action to launch segue.
    var addRelationSegueAction: Bool { get }
}

struct RelationInfoUIAssociatedKeys {
    static var relation = "RelationInfoUI.relation"
    static var relationName = "RelationInfoUI.relationName"
    static var relationFormat = "RelationInfoUI.relationFormat"
    //static var inverseRelationName = "RelationInfoUI.inverseRelationName"
    static var addRelationSegueAction = "RelationInfoUI.addRelationSegueAction"
}

extension UIControl: RelationInfoUI {

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

    @objc dynamic open var relationName: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)

            if addRelationSegueAction { // to deactivate set addRelationSegueAction before relationName
                self.addTarget(self, action: #selector(self.relationSegue(sender:)), for: .touchUpInside)

                // For buttons animation?
                self.addTarget(self, action: #selector(self.touchDown(sender:)), for: .touchDown)
                self.addTarget(self, action: #selector(self.touchUp(sender:)), for: .touchUpOutside)
            }
        }
    }
    @objc dynamic open var relationFormat: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            checkRelationFormat()
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
    @objc dynamic open var relation: Any? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relation)
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relation, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            checkRelationFormat()
        }
    }

    func checkRelationFormat() {
        if let newValue = self.relation {
            self.isEnabled = true

            if let record = newValue as? RecordBase { // -> 1 (not working if not data...)
                //print("\(newValue)")

                if let relationFormat = self.relationFormat,
                   !relationFormat.isEmpty,
                   let formatter = RecordFormatter(format: relationFormat, tableInfo: record.tableInfo) {

                    if let button = self as? UIButton { // bad case of...
                        button.setTitle(formatter.format(record), for: .normal)
                    }
                }

            } else { // -> N
                //print("\(newValue)")
            }
        } else {
            self.isEnabled = false

            if let button = self as? UIButton { // bad case of...
                if false { // ->1 // No info ...
                    button.setTitle("", for: .normal)
                }
            }
        }
    }

    #endif

    @objc func relationSegue(sender: UIControl!) {
        touchUp(sender: sender)
        guard let relationName = relationName else { return }
        guard let viewController = self.owningViewController else {
            logger.warning("Cannot find controller/form parent to make transition for relation \(relationName)")
            return
        }
        viewController.performSegue(withIdentifier: relationName, sender: sender)
    }
    @objc func touchDown(sender: UIControl!) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in //swiftlint:disable:this multiple_closures_with_trailing_closure
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                sender.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        }
    }
    @objc func touchUp(sender: UIControl!) {
        sender.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
}

extension UIButton {

    /// for relation element allow to force template by property (not by asset , assert is in automatic mode)
    @objc open var imageContextTemplate: Bool {
        get {
            return self.image(for: .normal)?.renderingMode == .alwaysTemplate
        }
        set {
            let state: UIControl.State = .normal // other state?
            if let image = self.image(for: state), image.renderingMode != .alwaysOriginal {
                if newValue {
                    setImage(image.withRenderingMode(.alwaysTemplate), for: state)
                } else {
                    setImage(image.withRenderingMode(.automatic), for: state) // XXX cannot restore default... or must keep in elsewhere
                }
            }
        }
    }

}
