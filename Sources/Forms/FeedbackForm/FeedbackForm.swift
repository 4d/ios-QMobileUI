//
//  ViewController.swift
//  Feedback
//
//  Created by phimage on 22/07/2018.
//  Copyright © 2018 phimage. All rights reserved.
//

import UIKit

/// Feedback form delegate.
public protocol FeedbackFormDelegate: AnyObject {

    func send(feedback: Feedback, dismiss: @escaping (Bool) -> Void)
    func discard(feedback: Feedback?)
}

/// A form to send feedback information
@IBDesignable
open class FeedbackForm: UIViewController {

    @IBOutlet var globalView: UIView!
    @IBOutlet open weak var mailTextField: UITextField!
    @IBOutlet open weak var textView: PlaceholderTextView!
    @IBOutlet open weak var separatorBar: UIView!
    @IBOutlet weak var informationLabel: UIBarButtonItem!

    open weak var delegate: FeedbackFormDelegate?
    open var feedback: Feedback?
    open var window: UIWindow?

    /// Set placeholder color every where
    @IBInspectable open var harmonizeColor: Bool = true

    open override func viewDidLoad() {
        super.viewDidLoad()
        if feedback?.attach == nil {
            informationLabel.title = ""
        }
        if let title = feedback?.title {
            self.navigationItem.title = title
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.foreground]
        }

        feedback?.restoreEmail()
        if harmonizeColor, let placeHolderColor = textView?.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            textView.placeholderColor = placeHolderColor
            separatorBar.backgroundColor = placeHolderColor
        }

        if let summaryPlaceholder = feedback?.summaryPlaceholder {
            textView.text = summaryPlaceholder
            textView.placeholder = summaryPlaceholder
        }

        if let email = feedback?.email {
            mailTextField.text = email
        }
        if self.traitCollection.userInterfaceStyle == .dark {
            globalView.backgroundColor = .black
            textView._textColor = .white
            informationLabel.tintColor = .white
        } else {
            globalView.backgroundColor = .white
            textView._textColor = .black
            informationLabel.tintColor = .black
        }
    }
    // MARK: Action
    @IBAction open func send(_ sender: Any) {
        if var feedback = feedback {
            feedback.email = mailTextField.text
            feedback.saveEmail()
            feedback.summary = textView.text
            if sender is UIBarButtonItem {
                let indicator = UIActivityIndicatorView(style: .medium)
                indicator.hidesWhenStopped = true
                // indicator.center = sendButton.center
                // sendButton.superview?.insertSubview(indicator, aboveSubview: sendButton)
                // sendButton.addSubview(indicator)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
                indicator.startAnimating()
            } else {
                logger.debug("Cannot add activity indicator, not more a UIBarButtonItem")
            }
            logger.debug("Will send feedback from \(String(describing: feedback.email))")
            background {
                self.delegate?.send(feedback: feedback) { animated in
                    foreground {
                        self.dismiss(animated: animated, completion: nil)
                    }
                }
            }
        } else {
            logger.warning("No feedback instance to send")
        }
    }

    @IBAction open func discard(_ sender: Any) {
        /*if textView.text.isEmpty {
            maybe dismiss without dialog
            return
        }*/
        let actionDialog = UIAlertController(title: "Discard report", message: "Are you sure you want to discard the report?", preferredStyle: .alert)

        actionDialog.addAction(UIAlertAction(title: "Stay", style: .default, handler: { _ in
            self.window = nil
        }))
        actionDialog.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.delegate?.discard(feedback: self.feedback)
            self.dismiss(animated: true, completion: nil)
            self.window = nil
        }))
        foreground {
            self.window = actionDialog.presentOnTop()
        }
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
    // swiftlint:disable:next identifier_name
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
        DispatchQueue.main.async {
            if self.textColor == self.placeholderColor {
                self.text = nil
                self.textColor = self._textColor
            }
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
