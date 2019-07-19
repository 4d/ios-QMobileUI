//
//  ViewController.swift
//  Feedback
//
//  Created by phimage on 22/07/2018.
//  Copyright © 2018 phimage. All rights reserved.
//

import UIKit

/// Feedback form delegate.
public protocol FeedbackFormDelegate: class {

    func send(feedback: Feedback, dismiss: @escaping (Bool) -> Void)
    func discard(feedback: Feedback?)

}

/// A form to send feedback information
@IBDesignable
open class FeedbackForm: UIViewController {

    @IBOutlet open weak var mailTextField: UITextField!
    @IBOutlet open weak var textView: PlaceholderTextView!
    @IBOutlet open weak var separatorBar: UIView!

    open weak var delegate: FeedbackFormDelegate?
    open var feedback: Feedback?

    /// Set placeholder color every where
    @IBInspectable open var harmonizeColor: Bool = true

    open override func viewDidLoad() {
        super.viewDidLoad()

        feedback?.restoreEmail()
        if harmonizeColor, let placeHolderColor = textView?.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            textView.placeholderColor = placeHolderColor
            separatorBar.backgroundColor = placeHolderColor
        }

        if let summaryPlaceholder = feedback?.summaryPlaceholder {
            textView.text = summaryPlaceholder
        }

        if let email = feedback?.email {
            mailTextField.text = email
        }
    }

    // MARK: Action
    @IBAction open func send(_ sender: Any) {
        if var feedback = feedback {
            feedback.email = mailTextField.text
            feedback.saveEmail()
            feedback.summary = textView.text
            delegate?.send(feedback: feedback) { animated in
                self.dismiss(animated: animated, completion: nil)
            }
        }
    }

    @IBAction open func discard(_ sender: Any) {
        let actionDialog = UIAlertController(title: "Discard report?", message: "Are you sure you want to discard the report?", preferredStyle: .alert)

        actionDialog.addAction(UIAlertAction(title: "Stay", style: .default, handler: { _ in
            // do nothing
        }))
        actionDialog.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.delegate?.discard(feedback: self.feedback)
            self.dismiss(animated: true, completion: nil)
        }))
        actionDialog.presentOnTop()
    }
}

extension Feedback {
    static let emailKey = "feedback.user.email"
    func saveEmail() {
        UserDefaults.standard[Feedback.emailKey] =  self.email
    }
    mutating func restoreEmail() {
        if let email = UserDefaults.standard[Feedback.emailKey] as? String {
            self.email = email
        }
    }
}

// MARK: listen to placeholder
extension FeedbackForm: UITextViewDelegate {

    open func textViewDidBeginEditing(_ fromDelegate: UITextView) {
        textView.startEditing()
    }
    open func textViewDidEndEditing(_ fromDelegate: UITextView) {
        textView.endEditing()
    }

}

// MARK: Placeholder on text view.

@IBDesignable
/// An `UITextView` with placeholder.
open class PlaceholderTextView: UITextView {

    // Keep current color to restore it
    //swiftlint:disable:next identifier_name
    var _textColor: UIColor?

    @IBInspectable open var placeholder: String = "" {
        didSet {
            configurePlaceholder()
        }
    }

    @IBInspectable open var placeholderColor: UIColor = ColorCompatibility.systemGray3 {
        didSet {
            configurePlaceholder()
        }
    }

    func configurePlaceholder() {
        if _textColor != nil {
            _textColor = self.textColor
        }
        self.text = placeholder
        self.textColor = placeholderColor
    }

    func startEditing() {
        if self.textColor == self.placeholderColor {
            self.text = nil
            self.textColor = _textColor
        }
    }

    func endEditing() {
        if self.text.isEmpty {
            configurePlaceholder()
        }
    }

}

extension FeedbackForm: IdentifiableProtocol { // XXX could be generic ?

    public var storyboardIdentifier: String? {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)
        return className
    }

    static var storyboardFromType: UIStoryboard {
        return UIStoryboard(name: String(describing: self), bundle: Bundle(for: LogForm.self))
    }

    static func instantiateNavigationControllerFromType() -> UINavigationController? {
        let initialVC = storyboardFromType.instantiateInitialViewController()
        return initialVC as? UINavigationController
    }

    static func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
        return self.storyboardFromType.instantiateViewController(ofType: type)
    }

    static func instantiate() -> FeedbackForm? {
        if let navigationController = FeedbackForm.instantiateNavigationControllerFromType() {
            if let logForm = navigationController.rootViewController as? FeedbackForm {
                return logForm
            }
            if let logForm = FeedbackForm.instantiateViewController(ofType: FeedbackForm.self) {
                navigationController.viewControllers = [logForm]
                return logForm
            }
            return nil
        } else {
            return FeedbackForm.instantiateViewController(ofType: FeedbackForm.self)
        }
    }
}
