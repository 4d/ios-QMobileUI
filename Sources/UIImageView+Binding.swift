//
//  UIImageView+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

/*
extension UIImageView {

    public var imageNamed: String? {
        get {
            return (self.image as? UIImageNamed)?.name
        }
        set {
            guard let name = newValue else {
                self.image = nil
            }
            self.image = UIImage(named: name)
        }
    }

}

// UIImage extension to keep a reference on the name
fileprivate class UIImageNamed: UIImage {
    fileprivate let name: String

    required init(imageLiteralResourceName name: String) {
        self.name = name
        super.init(imageLiteralResourceName: name)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}*/

// MARK: using URL and cache
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
