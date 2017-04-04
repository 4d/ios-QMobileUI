//
//  UIImageView+Qmobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

extension UIImageView {

    public convenience init(imageNamed: String) {
        self.init()
        image = UIImage(named: imageNamed)
    }
}
