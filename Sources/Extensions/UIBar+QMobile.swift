//
//  UIBar+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/02/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit

/// Protocol to easily copy attribute from one view to another.
protocol UIAppearanceCopyable: UIAppearance {

    func copyAppearance(from: Self, image: Bool)

}

extension UIAppearanceCopyable {
    /// Set to this object the share one from `Self.appearance()`
    func setAsDefaultStyle() {
        copyAppearance(from: Self.appearance(), image: true)
    }
    /// Take the current object appareance and set it to share one `Self.appearance()`
    func setDefaultStyle() {
        Self.appearance().copyAppearance(from: self, image: true)
    }
}

extension UINavigationBar: UIAppearanceCopyable {

    func copyAppearance(from bar: UINavigationBar, image: Bool = true) {
        self.isTranslucent = bar.isTranslucent
        self.barStyle = bar.barStyle
        self.barTintColor = bar.barTintColor
        self.tintColor = bar.tintColor
        self.prefersLargeTitles = bar.prefersLargeTitles
        self.titleTextAttributes = bar.titleTextAttributes
        if bar.largeTitleTextAttributes == nil {
            self.largeTitleTextAttributes = bar.titleTextAttributes // dirty fix, because large title do not work with asset
        } else {
            self.largeTitleTextAttributes = bar.largeTitleTextAttributes
        }
        if #available(iOS 13.0, *) {
            fillAppearance()
        }
        if image {
            self.backIndicatorImage = bar.backIndicatorImage
        }
    }

    @available(iOS 13.0, *)
    func fillAppearance() {
        let navBarAppearance = self.standardAppearance.copy() // UINavigationBarAppearance()
        // navBarAppearance.configureWithOpaqueBackground()
        if let titleTextAttributes = self.titleTextAttributes {
            navBarAppearance.titleTextAttributes = titleTextAttributes
        }
        if let largeTitleTextAttributes = self.largeTitleTextAttributes {
            navBarAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        }
        navBarAppearance.backgroundColor = self.backgroundColor ?? self.barTintColor

        self.standardAppearance = navBarAppearance
        self.compactAppearance = navBarAppearance
        self.scrollEdgeAppearance = navBarAppearance
    }
}

extension UITabBar: UIAppearanceCopyable {

    func copyAppearance(from bar: UITabBar, image: Bool = true) {
        self.barStyle = bar.barStyle
        self.barTintColor = bar.barTintColor
        self.tintColor = bar.tintColor
        self.isTranslucent = bar.isTranslucent
        if image {
            self.backgroundImage = bar.backgroundImage
            self.shadowImage = bar.shadowImage
        }
    }

}

extension UISearchBar: UIAppearanceCopyable {

    func copyAppearance(from bar: UISearchBar, image: Bool = true) {
        self.barStyle = bar.barStyle
        self.barTintColor = bar.barTintColor
        self.tintColor = bar.tintColor
        self.isTranslucent = bar.isTranslucent
        self.searchBarStyle = bar.searchBarStyle
        if image {
            self.backgroundImage = bar.backgroundImage
        }
    }

}

extension UINavigationBar {

    /// try to find default title view.
    func findTitleView(title: String?) -> UIView? {
        let labels = allSubviews.compactMap { $0 as? UILabel }
        for label in labels {
            if let title = title {
                if label.text == title {
                    return label
                } // else go on
            } else {
                return label // return first... (XXX maybe label elsewhere...)
            }
        }
        return nil
    }
}
