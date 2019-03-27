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
open class DialogForm: IBAnimatable.AnimatableModalViewController {

    @IBOutlet weak public var message: UILabel!
    @IBOutlet weak public var okButton: UIButton!
    @IBOutlet weak public var cancelButton: UIButton!
    @IBOutlet public var dummyCompileIssues: AnimatableModalViewController!

    @IBInspectable open var okMessage: String?
    @IBInspectable open var cancelMessage: String?

    weak public var delegate: DialogFormDelegate?

    // MARK: Actions
    @IBAction public func okAction(_ sender: Any) {
        self.delegate?.onOK(dialog: self, sender: sender)

        if let okMessage = okMessage {
            self.message.text = okMessage
        }
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
        self.isModalInPopover = true
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
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
