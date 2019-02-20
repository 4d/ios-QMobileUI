//
//  IndexPath+Utility.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension IndexPath {

    /// Is in first section
    var isFirstSection: Bool {
        return self.section == 0
    }

    // MARK: - Row

    /// Is not the first row
    var hasPreviousRow: Bool {
        return !isFirstRow
    }
    /// Is is first row in first section
    var isFirstRow: Bool {
        return self.isFirstSection && isFirstRowInSection
    }
    public static let firstRow = IndexPath(row: 0, section: 0)

    /// Is it the first row of one section
    var isFirstRowInSection: Bool {
        return self.row == 0
    }

    /// Is not the first row in one section
    var hasPreviousRowInSection: Bool {
        return self.row != 0
    }

    /// Provide next row in same action
    var nextRowInSection: IndexPath {
        return IndexPath(row: self.row + 1, section: self.section)
    }

    /// Provide previous row in same action
    var previousRowInSection: IndexPath {
        return IndexPath(row: self.row - 1, section: self.section)
    }

    // MARK: - Item
    var isFirstItem: Bool {
        return self.isFirstSection && self.isFirstItemInSection
    }
    var isFirstItemInSection: Bool {
        return self.item == 0
    }

    var hasPreviousItemInSection: Bool {
        return self.item != 0
    }

    var nextItemInSection: IndexPath {
        return IndexPath(item: self.item + 1, section: self.section)
    }

    var previousItemInSection: IndexPath {
        return IndexPath(item: self.item - 1, section: self.section)
    }

}
