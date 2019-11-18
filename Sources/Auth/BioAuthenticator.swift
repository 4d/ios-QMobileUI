//
//  BioAuthenticator.swift
//  QMobileUI
//
//  Created by Eric Marchand on 08/11/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import LocalAuthentication

class BioAuthentificator {

    public static var isAvailable: Bool {
        var error: NSError?
        if LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return (error == nil)
        }
        return false
    }

    public static var isFaceIDAvailable: Bool {
        if #available(iOS 11.0, *) {
            return (LAContext().biometryType == .faceID)
        }
        return false
    }

    /*static var isPasscodeEnabled: Bool { //  not bui
     return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
     }*/
}

extension LAError.Code {

    // get error message based on type
    public var errorDescription: String? {
        switch self {
        case .appCancel:
            return "Authentication was cancelled by application."
        case .authenticationFailed:
            return "The user failed to provide valid credentials."
        case .invalidContext:
            return "The context is invalid."
        case .userFallback:
            return "The user chose to use the fallback."
        case .userCancel:
            return "The user did cancel."
        case .passcodeNotSet:
            return "Passcode is not set on the device."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .biometryNotEnrolled:
            return "Biometric is not enrolled on the device."
        case .biometryLockout:
            return "Too many failed attempts."
        case .biometryNotAvailable:
            return "Biometric is not available on the device."
        default:
            return "Did not find error code message for LAError \(self)."
        }
    }
}
