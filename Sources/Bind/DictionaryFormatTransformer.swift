//
//  DictionaryFormatTransformer.swift
//  QMobileUI
//
//  Created by Eric Marchand on 30/08/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation

import ValueTransformerKit

class DictionaryFormatTransformer: ValueTransformer {

    var formatter: RecordFormatter

    init?(format: String) {
        guard let formatter = RecordFormatter(format: format) else {
            return nil
        }
        self.formatter = formatter
    }

    init(formatter: RecordFormatter) {
        self.formatter = formatter
    }

    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value as? NSDictionary {
            return formatter.format(value)
        }
        // XXX other type?
        return nil
    }

}
