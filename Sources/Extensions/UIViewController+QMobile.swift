//
//  UIViewController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIViewController {

    /// Recursively find a controller which could present the passed view controllers.
    /// FIXME Currently not working everytime, because `presentedViewController` could be filled even if not in hierachy.
    func findPresenter(of viewController: UIViewController) -> UIViewController? {
        // recursive
        for child in self.children {
            if let presentator = child.findPresenter(of: viewController) {
                return presentator
            }
        }
        for child in self.children where child.presentedViewController == viewController {
            return child
        }
        return nil
    }

    /// Dismiss current controller usingits `presentingViewController` or `navigationController`.
    /// if any of them, just call `dismiss`
    func previousPage(animated: Bool = true) {
        if let navigationController = navigationController {
            if navigationController.isFirstController(viewController: self) {
                if let presentingViewController = presentingViewController {
                    assert(navigationController.presentingViewController == presentingViewController) // check same presenting
                    // assert(presentingViewController.presentedViewController == navigationController)

                    // try to find the possible real presentator
                    // presentingViewController.printHierarchy()
                    let presentator = presentingViewController.findPresenter(of: navigationController) ?? presentingViewController
                    presentator.dismiss(animated: animated, completion: nil)
                }
            } else {
                navigationController.popViewController(animated: animated) // if root of navigation controller, this will do nothing
            }

        } else if let presentingViewController = presentingViewController {
            presentingViewController.dismiss(animated: animated, completion: nil)
        } else {
            self.dismiss(animated: animated, completion: nil)
        }
    }

    /// dismiss current controller usingits `presentingViewController` or `navigationController`.
    /// if any of them, just call `dismiss`
    @IBAction open func previousPage(_ sender: Any!) {
        previousPage()
    }

    /*@IBAction open func rootPage(_ sender: Any!) {
        let animated = false
        if let navigationController = navigationController {
            navigationController.popToRootViewController(animated: animated)
        }
    }*/

    /// Get recursively the parent controllers.
    public var parents: [UIViewController]? {
        guard let parent = self.parent else {
            return nil
        }
        guard let parents = parent.parents else {
            return [parent]
        }
        return parents + [parent]
    }

    /// Get view controller in hierarchy, brosing parent first, then presenting vc.
    public var hierarchy: [UIViewController]? {
        if let parent = self.parent {
            return [parent] + (parent.hierarchy ?? [])
        }
        if let presentingViewController = self.presentingViewController {
            return [presentingViewController] + (presentingViewController.hierarchy ?? [])
        }
        return nil
    }

    /// Try to get the controller at top of the stack.
    /// Will be seld if no `parent` or `presentingViewController`
    public var rootViewController: UIViewController? {
        if let parent = self.parent {
            return parent.rootViewController
        }
        if let presentingViewController = self.presentingViewController {
            return presentingViewController.rootViewController
        }
        // no panret or presenting, consider as root
        return self
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

    /// If in navigation controller, get the first one of its' child
    /// else return `self`.
    open var firstController: UIViewController {
        guard let navigation = self as? UINavigationController else {
            return self
        }
        return navigation.viewControllers.first ?? self
    }

    func isFirstController(viewController: UIViewController) -> Bool {
        guard let navigation = self as? UINavigationController else {
            return false
        }
        return viewController == navigation.viewControllers.first
    }

    var firstSelectedController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.viewControllers.first ?? self
        } else if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.firstController ?? self
        }
        return self
    }

    /// Add a gesture recognizer to main view of controller.
    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer?) {
        if let gestureRecognizer = gestureRecognizer {
            self.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    /// Remove a gesture recognizer to main view of controller.
    func removeGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer?) {
        if let gestureRecognizer = gestureRecognizer {
            self.view.removeGestureRecognizer(gestureRecognizer)
        }
    }

    /// Check if back button must be hidden (by removing it)
    /// For instance no need to a back button if we are one of the root controller in a `UITabBarController`
    func checkBackButton() {
        // Remove back back boutton if there is a tabBarController
        guard let tabBarController = self.tabBarController else {
            return
        }
        // and this controller is one of child controller
        guard let controllers = tabBarController.viewControllers else {
            return
        }
        guard let navigationController = self.navigationController else {
            return
        }
        let navigationBar = navigationController.navigationBar
        if controllers.contains(navigationController) {
            navigationBar.topItem?.leftBarButtonItems = nil

            // self.navigationItem.backBarButtonItem = nil
            // self.navigationItem.hidesBackButton = true
        } else if navigationController.isMoreNavigationController {
            // XXX maybe do some fix here...
        }
    }

    /// Instanciate a controller using its storyboard name and add it as a child.
    /// - parameter:
    ///
    func addChildViewController(storyboardName: String, bundle: Bundle? = nil) {
        if let childVc = UIStoryboard(name: storyboardName, bundle: bundle).instantiateInitialViewController() {
            addChild(childVc)
        }
    }

    // present constroller on new windows
    func presentOnTop(windowLevel: UIWindow.Level = UIWindow.Level.alert + 1, animated: Bool = true, completion: (() -> Swift.Void)? = nil) {
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = windowLevel
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(self, animated: animated, completion: completion)
    }

    func show(_ viewController: UIViewController? = UIApplication.topViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        viewController?.present(self, animated: animated, completion: completion)
        /// XXX assert or log viewController != nil
    }

    func embedIntoNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        if let topBar = UIApplication.topNavigationController?.navigationBar {
            navigationController.navigationBar.copyAppearance(from: topBar)
        }
        return navigationController
    }

    var navigationBarTitleView: UIView? {
        if let titleView = self.navigationItem.titleView {
            return titleView
        } else {
            return self.navigationController?.navigationBar.findTitleView(title: self.navigationItem.title)
        }
    }

    func applyScrollEdgeAppareance() {
        if #available(iOS 13.0, *) {
            guard let navigationBar = self.navigationController?.navigationBar else {
                return }
            let navBarAppearance = navigationBar.standardAppearance.copy() // UINavigationBarAppearance()
            // navBarAppearance.configureWithOpaqueBackground()
            if let titleTextAttributes = navigationBar.titleTextAttributes {
                navBarAppearance.titleTextAttributes = titleTextAttributes
            }
            if let largeTitleTextAttributes = navigationBar.largeTitleTextAttributes {
                navBarAppearance.largeTitleTextAttributes = largeTitleTextAttributes
            }
            navBarAppearance.backgroundColor = navigationBar.backgroundColor ?? navigationBar.barTintColor

            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
}

extension NSObject {
    /// For debug purpose, return a `String` to represent the object
    /// without adding any other information.
    fileprivate var debugString: String {
        return "\(type(of: self)):\(self.hash)"
    }

}

extension UIViewController {

    /// print some info aout self and linked controllers.
    private func printParentInfo() {
        print("----------------------------------------------------")
        print("self: \(String(describing: self))")
        print("tabBar: \(String(describing: self.tabBarController))")
        print("navigation: \(String(describing: self.navigationController))")
        print("navigation is more: \(String(describing: self.navigationController?.isMoreNavigationController))")
        print("presentation: \(String(describing: self.presentationController))")
        print("presented: \(String(describing: self.presentedViewController))")
        print("presenting: \(String(describing: self.presentingViewController))")

        print("children: \(self.children)")
        print("parent: \(String(describing: self.parent))")
        print("parents: \(String(describing: self.parents))")
        print("----------------------------------------------------")
    }

    /// recursively print information about this controller.
    private func printHierarchy() {
        UIViewController.printHierarchy(for: self)
    }

    /// recursively print information about controller.
    private static func printHierarchy(for viewController: UIViewController, depth: Int = 0) {
        let padding = String(repeating: " ", count: depth * 2)
        print("\(padding)\(viewController.debugString):")
        if let presented = viewController.presentedViewController {
            print("\(padding) - presented: \(presented.debugString)")
        }
        if let presenting = viewController.presentingViewController {
            print("\(padding) - presenting: \(presenting.debugString)")
        }
        print("\(padding) - children:")
        for child in viewController.children {
            printHierarchy(for: child, depth: depth + 1)
        }
    }
}
