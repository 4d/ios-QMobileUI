//
//  Collection+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Transform a collection into a dictionary
/// From: https://gist.github.com/ijoshsmith/0c966b1752b9a5722e23
extension Collection {

    func asDictionary<K, V>(transform: (_ element: Iterator.Element) -> [K: V]) -> [K: V] {
        var dictionary = [K: V]()
        self.forEach { element in
            for (key, value) in transform(element) {
                dictionary[key] = value
            }
        }
        return dictionary
    }

    func asDictionaryOfArray<K, V>(transform: (_ element: Iterator.Element) -> [K: V]) -> [K: [V]] {
        var dictionary = [K: [V]]()
        self.forEach { element in
            for (key, value) in transform(element) {
                if dictionary[key] == nil {
                    dictionary[key] = []
                }
                dictionary[key]?.append(value)
            }
        }
        return dictionary
    }
}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
