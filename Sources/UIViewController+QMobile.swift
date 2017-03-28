//
//  UIViewController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIViewController {

    static func topViewController(_ viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        #if !topVCCastDisabled
            if let navigationController = presentedViewController as? UINavigationController {
                if let visibleViewController = navigationController.visibleViewController {
                    return topViewController(visibleViewController)
                }
            } else if let tabBarController = presentedViewController as? UITabBarController {
                if let selectedViewController = tabBarController.selectedViewController {
                    return topViewController(selectedViewController)
                }
            }
        #endif
        return topViewController(presentedViewController)
    }

}
