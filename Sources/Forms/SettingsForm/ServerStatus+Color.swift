//
//  ServerStatus+Color.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import Result
import QMobileAPI

extension Result {

    /// Return a color accoding to value
    public var color: UIColor {
        switch self {
        case .success:
            return .statusSuccess
        case .failure:
            return .statusFailure
        }
    }

}
extension ServerStatus {
    /// A color associated with the server status
    public var color: UIColor {
        switch self {
        case .emptyURL, .notValidURL:
            return .statusFailure
        case .checking, .unknown:
            return .clear
        case .done(let result):
            return result.color
        }
    }
}
