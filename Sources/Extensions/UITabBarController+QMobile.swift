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
    }
}
