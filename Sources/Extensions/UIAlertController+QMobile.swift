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

    func dismissAction(title: String = "Cancel") -> UIAlertAction {
        return UIAlertAction(title: title, style: .cancel) { _ in
            self.dismiss(animated: true)
        }
    }

	/// Configure alert controller for iPad, by setting source view and rect
	func checkPopUp(_ sender: Any) -> UIAlertController {
		var alertController: UIAlertController = self
		if var popoverController = alertController.popoverPresentationController {
			// iPad use popover and need a source
			// we take the middle of the passed view
			if let gesture = sender as? UIGestureRecognizer, let view = gesture.view {
				popoverController.sourceView = view
				// let location = gesture.location(in: view)
				popoverController.sourceRect = CGRect(origin: view.bounds.mid, size: .zero)
			} else if let view = sender as? UIView {
				popoverController.sourceView = view
				popoverController.sourceRect = CGRect(origin: view.bounds.mid, size: .zero)
			} else if let viewController = sender as? UIViewController, let view = viewController.view {
				popoverController.sourceView = view
				popoverController.sourceRect = CGRect(origin: view.bounds.mid, size: .zero)
			} else if let view = UIApplication.shared.topWindow?.rootViewController?.view { // Get root view in last ressort
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(origin: view.bounds.mid, size: .zero)
            } else {
				// change style to avoid bug
				logger.warning("Unknown type for alert controller sender: \(sender) (Need a view or gesture)")
				alertController = UIAlertController(title: alertController.title, message: alertController.message, preferredStyle: .alert)
				popoverController = alertController.popoverPresentationController ?? popoverController
			}
			popoverController.permittedArrowDirections = []
		}
		return alertController
	}

}
extension UIAlertAction {

    public var leftImage: UIImage? {
        get {
            return self.value(forKey: "image") as? UIImage
        }
        set {
            self.setValue(newValue, forKey: "image")
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
