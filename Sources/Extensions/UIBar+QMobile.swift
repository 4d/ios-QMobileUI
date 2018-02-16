//
//  UIBar+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationBar {

    open func copyStyle(from bar: UINavigationBar, image: Bool = true) {
        self.barStyle = bar.barStyle
        self.barTintColor = bar.barTintColor
        self.tintColor = bar.tintColor
        self.isTranslucent = bar.isTranslucent
        self.prefersLargeTitles = bar.prefersLargeTitles
        if image {
            self.backIndicatorImage = bar.backIndicatorImage
        }
    }

    open func setAsDefaultStyle() {
        copyStyle(from: UINavigationBar.appearance())
    }

    open func setDefaultStyle() {
        UINavigationBar.appearance().copyStyle(from: self)
    }

}

extension UITabBar {

    func copyStyle(from bar: UITabBar, image: Bool = true) {
        self.barStyle = bar.barStyle
        self.barTintColor = bar.barTintColor
        self.tintColor = bar.tintColor
        self.isTranslucent = bar.isTranslucent
        if image {
            self.backgroundImage = bar.backgroundImage
            self.shadowImage = bar.shadowImage
        }
    }

    open func setAsDefaultStyle() {
        copyStyle(from: UITabBar.appearance())
    }

    open func setDefaultStyle() {
        UITabBar.appearance().copyStyle(from: self)
    }

}
