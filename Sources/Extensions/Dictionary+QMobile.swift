//
//  Dictionary+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Dictionary {
    init(_ array: [(Key, Value)]) {
        var dictionary = [Key: Value](minimumCapacity: array.count)
        array.forEach { dictionary[$0.0] = $0.1 }
        self = dictionary
    }
}
