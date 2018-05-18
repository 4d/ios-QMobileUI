//
//  QApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import IBAnimatable

@IBDesignable
open class DialogForm: AnimatableModalViewController {

    @IBOutlet weak public var message: UILabel!
    @IBOutlet weak public var okButton: UIButton!
    @IBOutlet weak public var cancelButton: UIButton!
    @IBOutlet weak public var activityIndicatorView: AnimatableActivityIndicatorView!

    @IBInspectable open var okMessage: String?
    @IBInspectable open var cancelMessage: String?

    weak public var delegate: DialogFormDelegate?

    // MARK: Actions
    @IBAction public func okAction(_ sender: Any) {
        self.delegate?.onOK(dialog: self, sender: sender)

        if let okMessage = okMessage {
            self.message.text = okMessage
        }
        self.okButton.isHidden = true

       // self.dismissOnTap = false // BUG IBAnimatable on change after loading view
        self.activityIndicatorView?.startAnimating()
    }

    @IBAction public func cancelAction(_ sender: Any) {
        self.delegate?.onCancel(dialog: self, sender: sender)
        if let cancelMessage = cancelMessage {
            self.message.text = cancelMessage
        }
        self.cancelButton.isHidden = true
    }

    // MARK: view
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        //okButton.transform = CGAffineTransform(scaleX: 0, y: 0)

        self.isModalInPopover = true

        /*UIView.animate(withDuration: 2.0,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 6.0,
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        self.okButton.transform = .identity
        }, completion: nil)

        cancelButton.transform = CGAffineTransform(scaleX: 0, y: 0)

        UIView.animate(withDuration: 2.0,
                       delay: 0.2,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 6.0,
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        self.cancelButton.transform = .identity
        }, completion: nil)*/
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.activityIndicatorView?.stopAnimating()
        super.dismiss(animated: flag, completion: completion)
    }

}

/// A delegate for Dialog form
public protocol DialogFormDelegate: NSObjectProtocol {

    /// Ok button touched
    func onOK(dialog: DialogForm, sender: Any)

    /// Cancel button touched
    func onCancel(dialog: DialogForm, sender: Any)
}
