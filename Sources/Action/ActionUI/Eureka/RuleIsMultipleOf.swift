//
//  RuleIsMultipleOf.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import Eureka
import QMobileAPI

public struct RuleIsMultipleOf<T: IsMultipleOf>: RuleType {

    let dividingBy: T
    public var id: String? // swiftlint:disable:this identifier_name
    public var validationError: ValidationError

    public init(dividingBy: T, msg: String? = nil, id: String? = nil) { // swiftlint:disable:this identifier_name
        let ruleMsg = msg ?? "Field value must be a multiple of \(dividingBy)"
        self.dividingBy = dividingBy
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    public func isValid(value: T?) -> ValidationError? {
        guard let val = value else { return nil }
        guard val.isMultiple(of: dividingBy) else { return validationError }
        return nil
    }

}
