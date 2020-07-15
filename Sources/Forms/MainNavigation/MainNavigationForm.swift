//
//  MainNavigationForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

// A form which present children forms.
public protocol MainNavigationForm {

    var childrenForms: [UIViewController] { get }

    func presentChildForm(_ form: UIViewController)
}

extension MainNavigationForm where Self: UITabBarController {

    public var childrenForms: [UIViewController] {
        return self.viewControllers ?? [] // TODO : check if more view controller self.moreNavigationController.children ??
    }

    public func presentChildForm(_ form: UIViewController) { // TODO callback completion generic?
        self.selectedViewController = form

        // dismiss controllers if not direct children in hierarchy
        if UIApplication.topViewController?.parent != self {
            self.dismiss(animated: true, completion: nil)
        }
    }

}
