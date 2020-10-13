//
//  ActionParameter+KeyboardType.swift
//  QMobileUI
//
//  Created by phimage on 13/10/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileAPI

extension ActionParameter {

    func keyboardType(with context: ActionContext) -> UIKeyboardType {
        if let format = self.format {
            switch format {
            case .email/* .emailAddress*/:
                return .emailAddress
            case .url:
                return .URL
            case .phone:
                return .phonePad
            default:
                break
            }
        }
        switch self.type {
        case .string, .text:
            return .default
        case .real, .number:
            return .decimalPad
        case .integer:
            return .numberPad
        default:
            return .default
        }
    }

}

extension UITextField {

    func from(actionParameter: ActionParameter, context: ActionContext) {
        self.placeholder = actionParameter.placeholder
        if let defaultValue = actionParameter.defaultValue(with: context) {
            self.text = "\(defaultValue)"
        }
        self.keyboardType = actionParameter.keyboardType(with: context)
    }

}
