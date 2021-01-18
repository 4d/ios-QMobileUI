//
//  ValidationError+LocalizedError.swift
//  QMobileUI
//
//  Created by phimage on 07/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import Eureka

extension ValidationError: LocalizedError {
    public var errorDescription: String? { return msg }

    public var failureReason: String? { return nil }

    public var recoverySuggestion: String? { return nil }

    public var helpAnchor: String? { return nil }
}
