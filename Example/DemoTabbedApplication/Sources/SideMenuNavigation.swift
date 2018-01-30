//
//  SideMenuNavigation.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 20/11/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import SideMenu

@IBDesignable
open class SideMenuNavigation: UISideMenuNavigationController {

    var menuManager: SideMenuManager {
        return .default
    }

    open var menuBlurEffectStyle: UIBlurEffectStyle? {
        get {
            return menuManager.menuBlurEffectStyle
        } set {
            menuManager.menuBlurEffectStyle = newValue
        }
    }

    private func attachMenu() {
        if self.leftSide {
            menuManager.menuLeftNavigationController = self
        } else {
            menuManager.menuRightNavigationController = self
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        menuManager.menuPushStyle = .preserve

        if self.parent == nil {

            /*if let controller = self.childViewControllers.first as? SideMenuTableViewController {
                let view = controller.tableView(controller.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
                
                
            }*/
            let storyboard = UIStoryboard(name: "Entity1ListForm", bundle: nil)

            if let controller = storyboard.instantiateInitialViewController() {
                self.present(controller, animated: false)
            }
        }
        self.attachMenu()
    }

    open static func present(on viewController: UIViewController) {
        let menuManager = SideMenuManager.default
        if let controller = menuManager.menuLeftNavigationController {
            viewController.present(controller, animated: true, completion: nil)
        } else if let controller = menuManager.menuRightNavigationController {
            viewController.present(controller, animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "SideMenu", bundle: nil)
            if let controller = storyboard.instantiateInitialViewController() as? SideMenuNavigation {
                controller.attachMenu()
                self.present(on: viewController)
            }
        }
    }
}

class SideMenuTableViewController: UITableViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // refresh cell blur effect in case it changed
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let navigation = self.parent as? SideMenuNavigation {
            (cell as? UITableViewVibrantCell)?.blurEffectStyle = navigation.menuManager.menuBlurEffectStyle
        }
        return cell
    }

}

extension UIViewController {

    @IBAction open func showSideMenu(_ sender: Any) {
        SideMenuNavigation.present(on: self)
    }

}
