//
//  UINavigationController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {

    /// Return true if its `moreNavigationController` of `tabBarController`.
    open var isMoreNavigationController: Bool {
        return self.tabBarController?.moreNavigationController == self
    }

}
