//
//  UISwitch+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
public extension UISwitch {

    func toggle(animated: Bool = true) {
        self.setOn(!self.isOn, animated: animated)
    }

}
