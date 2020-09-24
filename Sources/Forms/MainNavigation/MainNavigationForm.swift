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
public protocol MainNavigationForm: DeepLinkable {

    var childrenForms: [UIViewController] { get }

    func presentChildForm(_ form: UIViewController, completion: @escaping () -> Void)
}

extension MainNavigationForm where Self: UITabBarController {

    public var childrenForms: [UIViewController] {
        return self.viewControllers ?? [] // TODO : check if more view controller self.moreNavigationController.children ??
    }

    public func presentChildForm(_ form: UIViewController, completion: @escaping () -> Void) {
        self.selectedViewController = form
        logger.info("Select in nav bar a new form \(form)")
        // dismiss controllers if not direct children in hierarchy
        if let topVC = UIApplication.topViewController, topVC.parent != self {
            logger.info("Dismiss \(topVC) with parent \(String(describing: topVC.parent)) because not in root nav form")
            self.dismiss(animated: true) {
                completion()
            }
        }
    }

}

extension MainNavigationForm {
    public var deepLink: DeepLink? { return .navigation }
}
