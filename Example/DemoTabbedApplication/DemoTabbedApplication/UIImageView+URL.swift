//
//  UIImageView+URL.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {

    public var webURL: URL? {
        get {
            return self.kf.webURL
        }
        set {
            self.kf.indicatorType = .activity
            self.kf.setImage(with: newValue)
        }
    }

}
