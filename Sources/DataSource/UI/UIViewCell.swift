//
//  UIViewCell+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol UIViewCell {
    var parentView: UIView? { get }
    var parentViewSource: NSObjectProtocol? { get }

    var indexPath: IndexPath? { get }
}

private var xoAssociationKey: UInt8 = 0
extension UITableViewCell: UIViewCell {

    public var parentView: UIView? {
        get {
           return objc_getAssociatedObject(self, &xoAssociationKey) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }

    public var tableView: UITableView? {
        get {
            return self.parentView as? UITableView
        }
        set {
            self.parentView = newValue
        }
    }

    public var indexPath: IndexPath? {
        return self.tableView?.indexPath(for: self)
    }

}

extension UICollectionViewCell: UIViewCell {

    public var parentView: UIView? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }

    public var collectionView: UICollectionView? {
        get {
            return self.parentView as? UICollectionView
        }
        set {
            self.parentView = newValue
        }

    }

    public var indexPath: IndexPath? {
        return collectionView?.indexPath(for: self)
    }

}

extension UICollectionViewCell {

    public var parentViewSource: NSObjectProtocol? {
        if let parent = self.collectionView {
            return parent.dataSource as? DataSource
        }
        return nil
    }

}

extension UITableViewCell {

    public var parentViewSource: NSObjectProtocol? {
        if let parent = self.tableView {
            return parent.dataSource as? DataSource
        }
        return nil
    }

}
