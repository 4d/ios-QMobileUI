//
//  UITableViewController+Utility.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UITableViewController {

    // get all cells, could be time consuming, to do only for static table
    var cells: [UITableViewCell] {
        var cells = [UITableViewCell]()
        // assuming tableView is your self.tableView defined somewhere
        for i in 0...tableView.numberOfSections-1 {
            for j in 0...(tableView.numberOfRows(inSection: i) - 1) {
                if let cell = tableView.cellForRow(at: IndexPath(row: j, section: i)) {
                    cells.append(cell)
                }
            }
        }
        return cells
    }

}
