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
        /// Go the next form.
        case logged
        // could add passcode view, sign up view etc...

        var identifier: String? { return self.rawValue }
        var description: String { return "\(self.rawValue)" }

        var destination: UIViewController? {
            switch self {
            case .logged:
                return MainNavigation.instantiateInitialViewController()
            }
        }
    }

    /// Transition to perform
    var segue: Segue {
        return .logged
    }

}
