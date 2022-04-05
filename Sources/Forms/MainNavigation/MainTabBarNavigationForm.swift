//
//  MainTabBarNavigationForm.swift
//  QMobileUI
//
//  Created by emarchand on 01/03/2022.
//  Copyright © 2022 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// The main navigation controller of your application. Which use tab bar as navigation mode.
/// see https://developer.apple.com/documentation/uikit/uitabbarcontroller
open class MainTabBarNavigationForm: UITabBarController, MainNavigationForm, UITableViewDelegate {

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        customizeMoreView()
        initActions()
        checkFirstSelected()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onWillDisappear(animated)
    }

    final public override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDidDisappear(animated)
    }

    open override func viewDidLayoutSubviews() {
        customizeMoreView()
        // TODO: init action if needed too
        // initActions()
        super.viewDidLayoutSubviews()
    }

    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default transition to next controller.
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

    // MARK: functions

    open func customizeMoreView() {
        if let moreListViewController = moreNavigationController.topViewController {
            if let moreTableView = moreListViewController.view as? UITableView {
                moreTableView.tintColor = .background // To set color on  "more" panel table icon
                moreTableView.tableFooterView = UIView() // remove footer
                // moreTableView.separatorStyle = .none // to remove all separator
                moreTableView.delegate = self
            }
        }
        let navigationBar = self.moreNavigationController.navigationBar
        navigationBar.tintColor = .foreground
        navigationBar.barTintColor = .background

        if let delegate = self as? (MainNavigationForm & UITabBarControllerDelegate) {
            self.delegate = delegate
        }
    }

    func checkFirstSelected() {
        if self.selectedIndex == Int.max {
            self.selectedIndex = 0
        }
        if tabBar is MainTabBar {
            for (index, viewController) in (self.viewControllers ?? []).enumerated() where ((viewController.firstController is ActionsViewController) && (self.selectedIndex == index)) {
                self.selectedIndex += 1 // do not let ActionsViewController selectable at first try
            }
        }
    }

    func initActions() {
        if let mainBar = tabBar as? MainTabBar {
            for (index, viewController) in (self.viewControllers ?? []).enumerated() {
                if let acC = viewController.firstController as? ActionsViewController {
                    mainBar.setupActionButton(acC, index: index)
                }
            }
        }
    }

    // MARK: replace more controller delegate
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let tabBarController = self
        let tabCount = tabBarController.tabBar.items?.count ?? 0
        let children = tabBarController.viewControllers?[tabCount - 1 + indexPath.row]

        if children is ActionsViewController {
            let button = MoreListActionButton(frame: CGRect(origin: .zero, size: cell.frame.size).insetBy(dx: 5, dy: 5))
            button.actionSheet = children?.actionSheet
            button.showsMenuAsPrimaryAction = true
            button.setTitleColor(.foreground, for: .normal) // default is nil. use opaque white
            button.backgroundColor = .background
            button.layer.cornerRadius = 2
            let spacing: CGFloat = 8.0
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
            button.setTitle(cell.textLabel?.text ?? "", for: .normal)
            button.setImage(cell.imageView?.image, for: .normal)
            cell.addSubview(button)

            cell.textLabel?.isHidden = true
            cell.imageView?.isHidden = true
            cell.accessoryType = .none
        } else {
            cell.subviews.filter({ $0 is MoreListActionButton }).forEach {
                $0.removeFromSuperview()
            }
            cell.textLabel?.isHidden = false
            cell.imageView?.isHidden = false
            cell.accessoryType = .disclosureIndicator
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tabBarController = self
        let tabCount = tabBarController.tabBar.items?.count ?? 0
        let children = tabBarController.viewControllers?[tabCount - 1 + indexPath.row]

        if children is ActionsViewController {
            // nothing to do
        } else {
            // normal behaviour, calling original delegate
            assert(moreNavigationController.topViewController  is UITableViewDelegate)
            (moreNavigationController.topViewController as? UITableViewDelegate)?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }

}

class ActionTabBarButton: UIButton, ActionContextProvider {

    func actionContext() -> ActionContext? {
        return nil // If nil, let action provide its context
    }

}

class MoreListActionButton: UIButton {}

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
        guard let items = self.items, index < items.count else { return }
        let item = items[index]
        if let image = item.image {
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
                button.backgroundColor = UIColor.label.withAlphaComponent(0.1)
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
