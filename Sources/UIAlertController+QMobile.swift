//
//  UIAlertController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIAlertController {

    public static func show(title: String, message: String, cancelTitle: String = "OK") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        UIApplication.topViewController?.present(alertController, animated: true, completion: nil)
    }

}

/// Display an alert message
public func Alert(title: String, message: String) {
    UIAlertController.show(title: title, message: message)
}
