//
//  Main+Flow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/11/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences
import SwiftMessages
import QMobileAPI

extension Main: Storyboard {}

extension Main {

    /// Do in main thread segue transition according to application state.
    /// If logged, go to app, else go to login form.
    public final func performTransition(_ sender: Any? = nil) {
        foreground { [weak self] in
            guard let source = self else { return }
            let segue = source.segue

            if source.performSegue {
                // just perform the segue
                source.perform(segue: segue, sender: sender)
            } else {
                if let destination = segue.destination {
                    // prepare destination like done with segue
                    source.prepare(for: UIStoryboardSegue(identifier: segue.identifier, source: source, destination: destination), sender: sender)
                    // and present it
                    source.present(destination, animated: true) {
                        logger.debug("\(destination) presented by \(source)")
                    }
                }
            }
        }
    }

    /// Known transition of Main controller.
    enum Segue: String, CustomStringConvertible, SegueProtocol {
        /// Go the login form.
        case login
        /// Go to the navigaton form.
        case navigation

        var identifier: String? { return self.rawValue }
        var description: String { return "\(self.rawValue)" }
        var kind: SegueKind? {
            switch self {
            case .login:
                return SegueKind(rawValue: "push")
            case .navigation:
                return SegueKind(rawValue: "push")
            }
        }

        var destination: UIViewController? {
            switch self {
            case .login:
                return LoginForm.instantiate()
            case .navigation:
               return MainNavigation.instantiateInitialViewController()
            }
        }
    }

    /// Transition to perform
    var segue: Segue {
        guard Prephirences.Auth.Login.form else {
            return .navigation // no login form
        }
        if !Prephirences.Auth.Logout.atStart, let token = APIManager.instance.authToken, token.isValidToken {
            return .navigation // direct login
        }
        return .login // need login
    }

}
