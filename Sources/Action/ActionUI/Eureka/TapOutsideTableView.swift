//
//  TapOutsideTableView.swift
//  QMobileUI
//
//  Created by Eric Marchand on 01/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit

/// A delegate to receive table view tap outside the cells event.
protocol TapOutsideTableViewDelegate: UITableViewDelegate {
    func tableViewDidTapBelowCells(in tableView: UITableView)
}

/// A table view which could notify about a tap outside the cells
class TapOutsideTableView: UITableView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.indexPathForRow(at: point) == nil {
            if let delegate = self.delegate as? TapOutsideTableViewDelegate {
                delegate.tableViewDidTapBelowCells(in: self)
            }
        }
        return super.hitTest(point, with: event)
    }
}
