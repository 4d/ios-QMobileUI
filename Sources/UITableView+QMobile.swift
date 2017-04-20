//
//  UITableView+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
extension UITableView {
    func indexPath(for view: UIView) -> IndexPath? {
        let location = view.convert(CGPoint.zero, to: self)
        return indexPathForRow(at: location)
    }
}
