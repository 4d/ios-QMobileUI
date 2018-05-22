//
//  UITableView+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
extension UITableView {
    func indexPath(for view: UIView) -> IndexPath? {
        let location = view.convert(CGPoint.zero, to: self)
        return indexPathForRow(at: location)
    }
}

private var xoAssociationKey: UInt8 = 0
public typealias TableSectionIndex = Int
extension UITableViewHeaderFooterView {

    public var index: TableSectionIndex? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey) as? TableSectionIndex
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    public func reloadInTableView() {
        if let cell = self.parentCellView as? UITableViewCell,
            let tableView = cell.tableView,
            let index = index {
            let indexSet = IndexSet([index])
            tableView.reloadSections(indexSet, with: .none)
        }
    }

}
