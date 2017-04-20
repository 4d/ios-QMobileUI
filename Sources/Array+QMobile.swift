//
//  Array+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Array where Element: AnyObject {
    /// Delete comparing using ===
    /// Use a `Set` or use index if you can for more efficiency
    mutating func delete(_ element: Element) {
        self = self.filter { $0 !== element }
    }
}
