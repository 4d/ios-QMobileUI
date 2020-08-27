//
//  LoginForm+Flow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/11/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension LoginForm: Storyboardable {}

extension LoginForm {

    open func performTransition(_ sender: Any? = nil) {
        foreground { [weak self] in
            guard let source = self else { return }
            ApplicationCoordinator.instance.loginTransition(source, sender) // try here to cut segue model, and use coordinator
        }
    }

    /// Known transition of Main controller.
    enum Segue: String, CustomStringConvertible, SegueProtocol {
        /// Go the next form.
        case logged
        // could add passcode view, sign up view etc...

        var identifier: String? { return self.rawValue }
        var description: String { return "\(self.rawValue)" }

        var destination: UIViewController {
            switch self {
            case .logged:
                return MainNavigation.instantiateInitialViewController()!//swiftlint:disable:this force_cast
            }
        }
    }

    /// Transition to perform
    var segue: Segue {
        return .logged
    }

}

extension ApplicationCoordinator {

    func loginTransition(_ source: LoginForm, _ sender: Any? = nil) {
        let segue = source.segue
        performSegue(source, segue, source.performSegue, sender)
    }
}
