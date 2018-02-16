//
//  UIViewController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIViewController {

    @IBAction open func previousPage(_ sender: Any!) {
        let animated = true
        if let presentingViewController = presentingViewController {
            presentingViewController.dismiss(animated: animated, completion: nil)
        } else if let navigationController = navigationController {
            navigationController.popViewController(animated: animated)
        } else {
            self.dismiss(animated: animated, completion: nil)
        }
    }

    public var parents: [UIViewController]? {
        guard let parent = self.parent else {
            return nil
        }
        guard let parents = parent.parents else {
            return [parent]
        }
        return parents + [parent]
    }

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

    open var firstController: UIViewController {
        if let navigation = self as? UINavigationController {
            return (navigation.viewControllers.first ?? self)
        }
        return self
    }

    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer?) {
        if let gestureRecognizer = gestureRecognizer {
            self.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    func removeGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer?) {
        if let gestureRecognizer = gestureRecognizer {
            self.view.removeGestureRecognizer(gestureRecognizer)
        }
    }

    func checkBackButton() {
        // Remove back back boutton if there is a tabBarController
        guard let tabBarController = self.tabBarController else {
            return
        }
        // and this controller is one of child controller
        guard let controllers = tabBarController.viewControllers else {
            return
        }

        if controllers.contains(self.navigationController ?? self) {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItems = nil

            //self.navigationItem.backBarButtonItem = nil
           // self.navigationItem.hidesBackButton = true
        }
    }

    func addChildViewController(storyboardName: String, bundle: Bundle? = nil) {
        if let childVc = UIStoryboard(name: storyboardName, bundle: bundle).instantiateInitialViewController() {
            addChildViewController(childVc)
        }
    }

    private func printParentInfo() {
        print("----------------------------------------------------")
        print("self: \(String(describing: self))")
        print("tabBar: \(String(describing: self.tabBarController))")
        print("navigation: \(String(describing: self.navigationController))")
        print("navigation is more: \(String(describing: self.navigationController?.isMoreNavigationController))")
        print("presentation: \(String(describing: self.presentationController))")
        print("presented: \(String(describing: self.presentedViewController))")
        print("presenting: \(String(describing: self.presentingViewController))")

        print("children: \(self.childViewControllers)")
        print("parent: \(String(describing: self.parent))")
        print("parents: \(String(describing: self.parents))")
        print("----------------------------------------------------")
    }

}
