//
//  UILabel+BindToRelation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 05/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore

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
            checkRelationFormat()
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

    fileprivate func addRelationSegue() {
        if addRelationSegueAction && self.relationTapGesture == nil { // to deactivate set addRelationSegueAction before relationName
            self.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.relationTapped(_:)))
            self.relationTapGesture = gesture
            self.addGestureRecognizer(gesture)
            self.textColor = .relationLink
        }
    }

    fileprivate func removeRelationSegue() {
        if let relationTapGesture = self.relationTapGesture {
            self.removeGestureRecognizer(relationTapGesture)
        }
    }

    func checkRelationFormat() {
        if let record = self.relation as? RecordBase { // To One and not empty
            if let relationFormat = relationFormat,
               !relationFormat.isEmpty,
               let formatter = RecordFormatter(format: relationFormat, tableInfo: record.tableInfo) {
                self.text = formatter.format(record)
            }
            addRelationSegue()
        } else if self.relation is NSMutableSet { // to Many
            /*if relationLabel?.isTemplateString ?? false {
                relationLabel = relationFormat
            }*/
            if let relationFormat = relationLabel ?? relationFormat,
               !relationFormat.isEmpty {
                if let record = self.bindTo.record as? Record, let formatter = RecordFormatter(format: relationFormat, tableInfo: record.tableInfo) {
                    self.text = formatter.format(record)
                } else {
                    self.text = relationFormat
                }
            } else {
                let attachmentImage = NSTextAttachment()
                attachmentImage.image = UIImage.disclosureRelationImage
                self.attributedText = NSAttributedString(attachment: attachmentImage)
            }
            addRelationSegue()
        } else { // To One and empty
            if !self.text.isEmpty && (self.relationLabel?.isEmpty ?? true) {
                self.relationLabel = self.text
            }
            self.text = ""
            removeRelationSegue()
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
