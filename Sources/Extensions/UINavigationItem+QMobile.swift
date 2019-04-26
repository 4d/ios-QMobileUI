//
//  UINavigationItem+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationItem {
    enum Where {
        case left, right
    }

    func add(where location: Where = .right, item: UIBarButtonItem, at position: Int? = nil) {
        var items: [UIBarButtonItem]? = self.items(from: location)
        if items == nil {
            items = []
        }
        if let position = position {
            items?.insert(item, at: position)
        } else {
            items?.append(item)
        }
        setItems(where: location, items: items)
    }

    func items(from location: Where) -> [UIBarButtonItem]? {
        switch location {
        case .left:
            return self.leftBarButtonItems
        case .right:
            return self.rightBarButtonItems
        }
    }
    func item(from location: Where) -> UIBarButtonItem? {
        switch location {
        case .left:
            return self.leftBarButtonItem
        case .right:
            return self.rightBarButtonItem
        }
    }
    func setItems(where location: Where, items: [UIBarButtonItem]?) {
        switch location {
        case .left:
            self.leftBarButtonItems = items
        case .right:
            self.rightBarButtonItems = items
        }
    }

}
