//
//  Main+Flow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/11/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences

import QMobileAPI

extension Main: Storyboardable {}

extension Main {

    /// Do in main thread segue transition according to application state.
    /// If logged, go to app, else go to login form.
    public final func performTransition(_ sender: Any? = nil) {
        foreground { [weak self] in
            guard let this = self else { return }
            ApplicationCoordinator.instance.mainTransition(this, sender)
        }
    }

    /// Known transition of Main controller.
    enum Segue: String, CustomStringConvertible, SegueProtocol {
        /// Go the login form.
        case login
        /// Go to the navigaton form.
        case navigation
        /// Go to the setting url form.
        case settingURL

        var identifier: String? { return self.rawValue }
        var description: String { return "\(self.rawValue)" }
        var kind: SegueKind? {
            switch self {
            case .login, .navigation, .settingURL:
                return SegueKind(rawValue: "push")
            }
        }

        var destination: UIViewController {
            switch self {
            case .login:
                return LoginForm.instantiate()!//swiftlint:disable:this force_cast
            case .navigation:
                return MainNavigation.instantiateInitialViewController()!//swiftlint:disable:this force_cast
            case .settingURL:
                return SettingURLForm.instantiateInitialViewController()!//swiftlint:disable:this force_cast
            }
        }
    }

    /// Transition to perform
    func segue(for deepLink: DeepLink) -> Segue {
        switch deepLink {
        case .settings:
            return .settingURL
        case .navigation:
            return .navigation
        case .login:
            return .login
        default:
            return .login // need login
        }
    }

}

extension ApplicationCoordinator {

    func mainTransitionDeepLink() -> DeepLink {
        if Prephirences.Reset.serverAddress {
            return .settings // not really settings url but...
        }
        if !ApplicationAuthenticate.hasLogin {
            return .navigation // direct login
        }
        if !Prephirences.Auth.Logout.atStart, !APIManager.isSignIn {
            return .login([:]) // need login (app start info here?)
        }
        return .navigation
    }

    func mainTransition(_ source: Main, _ sender: Any? = nil) {
        let segue = source.segue(for: self.mainTransitionDeepLink())
        performSegue(source, segue, source.performSegue, sender)
    }

    func performSegue<T: SegueProtocol>(_ source: UIViewController, _ segue: T, _ withSegue: Bool, _ sender: Any?) {
        if withSegue {
            // just perform the segue
            // according to app state we
            source.perform(segue: segue, sender: sender)
        } else {
            // if not segue, create storyboard from destination definition and segue
            let destination = segue.destination
            // prepare destination like done with segue
            source.prepare(for: UIStoryboardSegue(identifier: segue.identifier, source: source, destination: destination), sender: sender)
            // and present it
            source.present(destination, animated: true) {
                logger.debug("\(destination) presented by \(source)")
            }
        }
    }
}
