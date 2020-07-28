//
//  RowOfIsMultipleOf.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI
import Eureka

protocol RowOfIsMultipleOf: BaseRowType {
    func setMultiple(of divideBy: Any?, msg: String?)
}

extension RowOf: RowOfIsMultipleOf where T: IsMultipleOf {
    func setMultiple(of value: Any?, msg: String?) {
        self.remove(ruleWithIdentifier: "actionParameterIsMultipleOf")
        if let value = value as? T {
            let rule = RuleIsMultipleOf(dividingBy: value, msg: msg, id: "actionParameterIsMultipleOf")
            self.add(rule: rule)
        } else if let value = value {
            logger.debug("Wrong type for multiple of \(value) \(type(of: value)) vs \(T.self)")
        }
    }
}
