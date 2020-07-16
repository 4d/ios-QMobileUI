//
//  UIScene+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/07/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import UIKit

extension UIScene.OpenURLOptions {
    public var app: [UIApplication.OpenURLOptionsKey: Any] {
        var options: [UIApplication.OpenURLOptionsKey: Any] = [.openInPlace: self.openInPlace]
        if let annotation = self.annotation {
            options[.annotation] = annotation
        }
        if let sourceApplication = self.sourceApplication {
            options[.sourceApplication] = sourceApplication
        }
        return options
    }
}
