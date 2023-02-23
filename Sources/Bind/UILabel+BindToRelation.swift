//
//  UILabel+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 05/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore
import QMobileAPI // emptyable protocol

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
            checkRelationFormat()
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
            // checkRelationFormat()
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
            return self.text
        }
        set {
            self.text = newValue
        }
    }

    public func setRelationDisclosure() {
        let attachmentImage = NSTextAttachment()
        attachmentImage.image = UIImage.disclosureRelationImage
        self.attributedText = NSAttributedString(attachment: attachmentImage)
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

    public func addRelationSegue() {
        if addRelationSegueAction && self.relationTapGesture == nil { // to deactivate set addRelationSegueAction before relationName
            self.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.relationTapped(_:)))
            self.relationTapGesture = gesture
            self.addGestureRecognizer(gesture)
            self.textColor = .relationLink
        }
    }

    public func removeRelationSegue() {
        if let relationTapGesture = self.relationTapGesture {
            self.removeGestureRecognizer(relationTapGesture)
        }
    }

}

extension String {
    var isTemplateString: Bool {
        return self.first == "<" && self.last == ">"
    }
}

extension UIColor {
    /// Color for relatio link. Use "relationLink" asset name to define it or use .link
    static var relationLink: UIColor = {
        return UIColor(named: "relationLink") ?? .link
    }()
}

extension UIImage {
    /// image when we are not able to know the label for relation widget ... use by default system  "arrow.right.circle" but could be overrided by asset image named "disclosureRelation"
    static var disclosureRelationImage: UIImage? {
        return UIImage(named: "disclosureRelation") ?? UIImage(systemName: "arrow.right.circle")?.withRenderingMode(.alwaysTemplate)
    }
}
