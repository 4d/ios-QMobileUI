//
//  Storyboardable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 02/09/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit

/// Object which can be associated to a `Storyboard`.
public protocol Storyboardable {
    /// Returne the storyboard.
    static var storyboard: UIStoryboard { get }
    /// The storynoard identifier.
    static var storyboardIdentifier: String { get }
    /// The storyboard bundle.
    static var storyboardBundle: Bundle? { get }
}

extension Storyboardable {
    public static var storyboard: UIStoryboard {
        return UIStoryboard(name: self.storyboardIdentifier, bundle: storyboardBundle)
    }

    public static var storyboardBundle: Bundle? {
        return nil // main bundle
    }

    public static func instantiateNavigationViewController() -> UINavigationController? {
        return self.storyboard.instantiateInitialViewController() as? UINavigationController
    }
    public static func instantiateInitialViewController() -> UIViewController? {
        return self.storyboard.instantiateInitialViewController()
    }
}

extension Storyboardable where Self: UIViewController {
    public static var storyboardIdentifier: String {
        return self.className
    }
    public static func instantiate() -> Self? {
        return self.storyboard.instantiateInitialViewController() as? Self
    }
}
