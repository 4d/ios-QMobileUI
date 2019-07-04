//
//  RowOfComparable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 04/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

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
        } else if let value = value {
            logger.debug("Wrong type for max \(value) \(type(of: value)) vs \(T.self)")
        }
    }
    func setGreaterOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterGreaterThan")
        if let value = value as? T {
            self.add(rule: RuleGreaterOrEqualThan(min: value, id: "actionParameterGreaterThan"))
        } else if let value = value {
            logger.debug("Wrong type for max \(value) \(type(of: value)) vs \(T.self)")
        }
    }
    func setSmaller(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerThan(max: value, id: "actionParameterSmallerThan"))
        } else if let value = value {
            logger.debug("Wrong type for max \(value) \(type(of: value)) vs \(T.self)")
        }
    }
    func setSmallerOrEqual(than value: Any?) {
        self.remove(ruleWithIdentifier: "actionParameterSmallerThan")
        if let value = value as? T {
            self.add(rule: RuleSmallerOrEqualThan(max: value, id: "actionParameterSmallerThan"))
        } else if let value = value {
            logger.debug("Wrong type for max \(value) \(type(of: value)) vs \(T.self)")
        }
    }
}
