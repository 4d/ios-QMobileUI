//
//  UIAlertController+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIAlertController {

    fileprivate static func show(title: String, message: String?, cancelTitle: String = "OK") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let viewController = UIApplication.topViewController {
            viewController.present(alertController, animated: true, completion: nil)
        } else {
            // Too soon maybe
            DispatchQueue.main.after(5) {
                show(title: title, message: message, cancelTitle: cancelTitle)
            }
        }
    }

}

/// Display an alert message
public func alert(title: String, message: String? = nil) {
    UIAlertController.show(title: title, message: message)
}

public func alert(title: String, error: Error) {
    alert(title: title, message: "\(error)")
}

// XXX could be replaced with framework SwiftMessages
