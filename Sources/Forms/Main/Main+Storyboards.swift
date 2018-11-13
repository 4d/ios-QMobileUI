//
//  Main.swift
//  QMobileUI
//
//  Created by Eric Marchand on Wed, 07 Nov 2018 13:57:21 GMT
//  ©2018 My Company All rights reserved

import UIKit

struct Storyboards {

    struct Main: Storyboard {

        static let identifier = "Main"

        static var storyboard: UIStoryboard {
            return UIStoryboard(name: self.identifier, bundle: nil)
        }

        static func instantiateInitialViewController() -> UINavigationController {
            //swiftlint:disable:next force_cast
            return self.storyboard.instantiateInitialViewController() as! UINavigationController
        }

        static func instantiateViewController(withIdentifier identifier: String) -> UIViewController {
            return self.storyboard.instantiateViewController(withIdentifier: identifier)
        }

        static func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
            return self.storyboard.instantiateViewController(ofType: type)
        }

    }
}

extension Main {

    enum Segue: String, CustomStringConvertible, SegueProtocol {
        case login
        case navigation

        var kind: SegueKind? {
            switch self {
            case .login:
                return SegueKind(rawValue: "push")
            case .navigation:
                return SegueKind(rawValue: "push")
            }
        }

        var identifier: String? { return self.rawValue }
        var description: String { return "\(self.rawValue)" }
    }

}
