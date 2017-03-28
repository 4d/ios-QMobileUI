//
//  IndexPath+Utility.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension IndexPath {

    var isFirstSection: Bool {
        return self.section == 0
    }

    // Row
    var hasPreviousRow: Bool {
        return !isFirstRow
    }
    var isFirstRow: Bool {
        return self.isFirstSection && isFirstRowInSection
    }
    static let firstRow = IndexPath(row: 0, section: 0)

    var isFirstRowInSection: Bool {
        return self.row == 0
    }

    var hasPreviousRowInSection: Bool {
        return self.row != 0
    }

    var nextRowInSection: IndexPath {
        return IndexPath(row: self.row + 1, section: self.section)
    }

    var previousRowInSection: IndexPath {
        return IndexPath(row: self.row - 1, section: self.section)
    }

    // Item
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
