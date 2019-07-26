//
//  NSSet+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 26/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

/// Make set implement KVO with "count" key.
extension NSSet {

    open override func value(forKeyPath keyPath: String) -> Any? {
        if keyPath == "count" || keyPath == "@count" {
            return self.count
        }
        return nil
    }
}

/// Make set implement KVO with "count" key and [index number]
extension NSOrderedSet {

    open override func value(forKeyPath keyPath: String) -> Any? {
        if keyPath == "count" || keyPath == "@count" {
            return self.count
        } else if keyPath.starts(with: "["), let closeIndex = keyPath.firstIndex(of: "]") {
            let openIndex = keyPath.index(keyPath.startIndex, offsetBy: 1)
            let indexString = keyPath[openIndex..<closeIndex]

            if let index = Int(indexString), index < self.count {
                return object(at: index)
            }
        }
        return nil
    }
}
