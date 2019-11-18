//
//  DetailHighlightedRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Eureka

/// Protocol to manage color when Highlighted.
protocol DetailHighlightedRow: BaseRowType {
    var isHighlighted: Bool { get }
}

extension DateRow: DetailHighlightedRow {}
extension TimeIntervalRow: DetailHighlightedRow {}
extension CountDownTimeRow: DetailHighlightedRow {}

extension DetailHighlightedRow {

    func updateHighlighted() {
        guard let cell = baseCell else { return }
        if self.isHighlighted {
            cell.detailTextLabel?.textColor = cell.tintColor
        } else {
            cell.detailTextLabel?.textColor = UITableViewCell(style: .value1, reuseIdentifier: nil).detailTextLabel?.textColor // reset default color, better way is to get previous, store it and restore it here
        }
    }
}
