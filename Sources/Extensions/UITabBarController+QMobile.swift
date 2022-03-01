//
//  UITabBarController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 06/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UITabBarController {

    open func enable(atindex index: Int = 0, _ status: Bool = true) {
        if let item = self.tabBar.items?[index] {
            item.isEnabled = status
        }
    }

    open func renderOriginalImages() {
        guard let items = tabBar.items, !items.isEmpty else { return }

        for item in items {
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal)
        }
    }

    open func customizeMoreView() {

        if let moreListViewController = moreNavigationController.topViewController {
            if let moreTableView = moreListViewController.view as? UITableView {
                moreTableView.tintColor = .background // To set color on  "more" panel table icon
                moreTableView.tableFooterView = UIView() // remove footer
                // moreTableView.separatorStyle = .none // to remove all separator
            }
        }
        let navigationBar = self.moreNavigationController.navigationBar
        navigationBar.tintColor = .foreground
        navigationBar.barTintColor = .background

        if let delegate = self as? (MainNavigationForm & UITabBarControllerDelegate) {
            self.delegate = delegate
        }

        initActions()
    }

    func initActions() {
        if self.selectedIndex == Int.max {
            self.selectedIndex = 0
        }

        if let mainBar = tabBar as? MainTabBar {
            for (index, viewController) in (self.viewControllers ?? []).enumerated() {
                if let acC = viewController.firstController as? ActionViewController {
                    mainBar.setupActionButton(acC, index: index)
                    if self.selectedIndex == index {
                        self.selectedIndex += 1 // do not let ActionViewController selectable at first try
                    }
                }
            }
        }
    }
}
import QMobileAPI
class ActionTabBarButton: UIButton, ActionContextProvider {

    func actionContext() -> ActionContext? {
        return nil // If nil, let action provide its context
    }

}

open class MainTabBar: UITabBar {

    private var buttons: [UIButton?] = []

    open override func awakeFromNib() {
        super.awakeFromNib()
        buttons = [UIButton?](repeating: nil, count: self.items?.count ?? 0)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden {
            return super.hitTest(point, with: event)
        }
        for button in buttons {
            if let button = button, button.frame.contains(point) {
               return button
            }
        }

        return super.hitTest(point, with: event)
    }

    var tabBarButtons: [UIView] {
        return self.subviews.filter { $0.isTabBarButton }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let tabBarButtons = self.tabBarButtons
        for (index, button) in buttons.enumerated() {
            if let button = button {
                setupActionButton(index, button, tabBarButtons[safe: index])
            }
        }
    }

    override open func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        super.setItems(items, animated: animated)
    }

    fileprivate func setupActionButton(_ index: Int, _ button: UIButton, _ tabBarButton: UIView?) {
        button.frame = tabBarButton?.frame ?? .zero

        if let item = self.items?[index], let image = item.image {
            if item.title.isEmpty { // as requested, if no title, enlarge the image
                if button.image(for: .normal) == nil { // check to not it each time
                    button.setImage(image, for: .normal)
                    button.imageView?.contentMode = .scaleAspectFit
                    button.contentVerticalAlignment = .fill
                    button.contentHorizontalAlignment = .fill
                    button.contentEdgeInsets = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
                }

                tabBarButton?.subviews.forEach({ $0.removeFromSuperview() })
            } else {
                // we let default button item but add some background
                button.backgroundColor = .label.withAlphaComponent(0.1)
                button.layer.cornerRadius = 5
            }
        }
    }

    fileprivate func setupActionButton(_ viewController: UIViewController, index: Int) {
        let button = ActionTabBarButton()
        buttons[index] = button

        if viewController.actionSheet?.actions.count == 1 {
            button.actionIndex = 0
        }
        button.actionHasDeferred = false
        button.actionSheet = viewController.actionSheet
        if button.actionIndex == 0 {
            button.setTitle("", for: .normal)
        }
        button.showsMenuAsPrimaryAction = true
        setupActionButton(index, button, nil)
        addSubview(button)
    }

}

private extension UIView {

    var isTabBarButton: Bool {
        String(describing: type(of: self)) == "UITabBarButton"
    }

}
