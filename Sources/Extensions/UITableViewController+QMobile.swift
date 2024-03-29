//
//  UITableViewController+Utility.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController {

    // get all cells, could be time consuming, to do only for static table
    var cells: [UITableViewCell] {
        var cells = [UITableViewCell]()
        // assuming tableView is your self.tableView defined somewhere
        // swiftlint:disable:next identifier_name
        for i in 0...tableView.numberOfSections-1 {
            // swiftlint:disable:next identifier_name
            for j in 0...(tableView.numberOfRows(inSection: i) - 1) {
                if let cell = tableView.cellForRow(at: IndexPath(row: j, section: i)) {
                    cells.append(cell)
                }
            }
        }
        return cells
    }

}

extension UITableViewController {

    public func reload<S: RawRepresentable>(section: S) where S.RawValue == Int {
        assert(Thread.isMainThread)
        self.tableView.reloadSections(section.indexSet, with: .none)
    }

    public func assertTableViewAttached() {
        assert(tableView.dataSource === self)
        assert(tableView.delegate === self)
    }

    public func forceUpdates(with closure: (() -> Void)? = nil ) {
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        closure?()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}
