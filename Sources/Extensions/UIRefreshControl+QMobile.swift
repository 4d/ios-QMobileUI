//
//  UIRefreshControl+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public extension UIRefreshControl {

    @objc dynamic var title: String? {
        get {
            guard let attributedTitle = self.attributedTitle else {
                return nil
            }
            return attributedTitle.string
        }
        set {
            if let title = newValue {
                attributedTitle = NSAttributedString(string: title)
            } else {
                attributedTitle = nil
            }
        }
    }
}
