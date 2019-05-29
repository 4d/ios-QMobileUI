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

extension RowOf: RowOfEquatable where T: Equatable {
    func setRequired(_ value: Bool) {
        self.remove(ruleWithIdentifier: "actionParameterRequired")
        if value {
            self.add(rule: RuleRequired(id: "actionParameterRequired"))
        }
    }
}

protocol RowOfComparable: BaseRowType {
    func setGreater(than value: Any?)
    func setGreaterOrEqual(than value: Any?)
    func setSmaller(than value: Any?)
    func setSmallerOrEqual(than value: Any?)
}

extension RowOf: RowOfComparable where T: Comparable {
    func setGreater(than value: Any?) { // , orEqual: Bool = false
        self.remove(ruleWithIdentifier: "actionParameterGreaterThan")
        if let value = value as? T {
            self.add(rule: RuleGreaterThan(min: value, id: "actionParameterGreaterThan"))
        }
    }
    func setGreaterOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterGreaterThan")
        if let value = value as? T {
            self.add(rule: RuleGreaterOrEqualThan(min: value, id: "actionParameterGreaterThan"))
        }
    }
    func setSmaller(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerThan(max: value, id: "actionParameterSmallerThan"))
        }
    }
    func setSmallerOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerOrEqualThan(max: value, id: "actionParameterSmallerThan"))
        }
    }
}

func onRowValidationTests<Row>(row: Row, _ callback: @escaping (_ cell: Row.Cell, _ row: Row) -> Void) where Row: BaseRow, Row: RowType {
    row.validationOptions = ValidationOptions.validatesOnChange
    row.onRowValidationChanged(callback)
}
