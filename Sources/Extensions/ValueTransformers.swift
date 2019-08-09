//
//  ValueTransformers.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import ValueTransformerKit

// A value transformer to add a prefix to value.
class StringPrefixer: ValueTransformer, ValueTransformerRegisterable {
    static let namePrefix = "StringPrefixer"
    static let defaultSeparator = "StringPrefixer"
    var name: NSValueTransformerName {
        return NSValueTransformerName(StringPrefixer.namePrefix + prefix)
    }

    let prefix: String
    let separator: String

    init(prefix: String, separator: String = StringPrefixer.defaultSeparator) {
        self.prefix = prefix
        self.separator = separator
    }

    open override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }
        return "\(self.prefix)\(separator)\(value)"
    }

    open override class func allowsReverseTransformation() -> Bool {
        return false // reverse transformation will only work for string, so not implemeted if not needed
    }
}
