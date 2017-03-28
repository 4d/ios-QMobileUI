//
//  DetailsFormViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

open class DetailsFormViewController: UIViewController, DetailsFormController {

}

open class DetailsFormTableViewController: UITableViewController, DetailsFormController {

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let staticCell = super.tableView(tableView, cellForRowAt: indexPath)
        staticCell.tableView = self.tableView

        staticCell.record = self.tableView.record
        staticCell.table = self.tableView.table

        return staticCell
    }

}

extension UITableView {

    // use only for static table view and debug
    var cells: [UITableViewCell] {
        var cells = [UITableViewCell]()
        let sections = self.numberOfSections
        for section in 0..<sections {
            let rows = self.numberOfRows(inSection: section)
            for row in 0..<rows {
                if let cell = self.cellForRow(at: IndexPath(row: row, section: section)) {
                    cells.append(cell)
                }
            }
        }
        return cells
    }

}
