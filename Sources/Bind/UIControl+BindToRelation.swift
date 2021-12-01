//
//  UIControl+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore // TODO break dependences?; instance of ?
import QMobileAPI // emptyable protocol

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
    @objc dynamic open var relationDisplayedValue: String? {
        get { return nil }
        set {} // swiftlint:disable:this unused_setter_value
    }
    #else

    @objc dynamic open  var relationName: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationName, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)

        }
    }

    @objc dynamic open var relationFormat: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationFormat, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            // checkRelationFormat()
        }
    }

    @objc dynamic open var relationLabel: String? {
        get {
            return objc_getAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationLabel) as? String
        }
        set {
            objc_setAssociatedObject(self, &RelationInfoUIAssociatedKeys.relationLabel, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            checkRelationFormat()
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

#endif

    @objc dynamic open var relationDisplayedValue: String? {
        get {
            return (self as? UIButton)?.title(for: .normal) // Manage only button from now, override to do something else
        }
        set {
            (self as? UIButton)?.setTitle(newValue, for: .normal)
        }
    }

    open func setRelationDisclosure() {
        self.relationDisplayedValue = ""
        (self as? UIButton)?.setImage(UIImage.disclosureRelationImage, for: .normal)
    }

    open func addRelationSegue() {
        self.isEnabled = true
        if addRelationSegueAction { // to deactivate set addRelationSegueAction before relationName
            self.addTarget(self, action: #selector(self.relationSegue(sender:)), for: .touchUpInside)

            // For buttons animation?
            self.addTarget(self, action: #selector(self.touchDown(sender:)), for: .touchDown)
            self.addTarget(self, action: #selector(self.touchUp(sender:)), for: .touchUpOutside)
        }
    }

    open func removeRelationSegue() {
        self.isEnabled = false
        if addRelationSegueAction { // to deactivate set addRelationSegueAction before relationName
            self.removeTarget(self, action: #selector(self.relationSegue(sender:)), for: .touchUpInside)

            self.removeTarget(self, action: #selector(self.touchDown(sender:)), for: .touchDown)
            self.removeTarget(self, action: #selector(self.touchUp(sender:)), for: .touchUpOutside)
        }
    }

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
        }) { _ in // swiftlint:disable:this multiple_closures_with_trailing_closure
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
