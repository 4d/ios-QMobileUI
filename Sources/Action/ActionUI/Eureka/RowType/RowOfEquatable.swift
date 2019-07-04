//
//  Eureka+RowRules.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

protocol RowOfEquatable: BaseRowType {
    func setRequired(_ value: Bool)
}
extension RowOfEquatable {

    func setRequired() {
        setRequired(true)
    }
}

private let kRuleId = "actionParameterRequired"
extension RowOf: RowOfEquatable where T: Equatable {
    func setRequired(_ value: Bool) {
        self.remove(ruleWithIdentifier: kRuleId)
        if value {
            self.add(rule: RuleRequired(id: kRuleId))
        }
    }
}
