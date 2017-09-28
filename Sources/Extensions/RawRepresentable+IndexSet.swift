//
//  RawRepresentable+IndexSet.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension RawRepresentable where RawValue == Int {

    public var indexSet: IndexSet {
        return IndexSet(integer: rawValue)
    }

    public static func == (section: Self, value: Int) -> Bool {
        return section.rawValue == value
    }

}
