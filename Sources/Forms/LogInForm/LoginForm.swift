//
//  LoginForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 09/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences
import Moya

import SwiftMessages

import QMobileAPI
import QMobileDataSync

/// Form to login
@IBDesignable
open class LoginForm: UIViewController {

    /// Identifier for segue when successfuly logged. Default value "logged"
    @IBInspectable open var loggedSegueIdentifier: String = "logged"

    /// Segue to go to passcode form
    //@IBInspectable open var passcodeSegueIdentifier: String = "passcode"

    /// Constaint for view at the bottom.
    @IBOutlet weak open var bottomLayoutConstraint: NSLayoutConstraint!

    /// The login buttons.
    @IBOutlet open weak var loginButton: LoadingButton!
    /// The text field for the login information ie. the email.
    @IBOutlet open weak var loginTextField: FloatingLabelTextField!

    var cancellable: Cancellable?

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginButton.isUserInteractionEnabled = false
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
        onWillDisappear(animated)
    }

    final public override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDidDisappear(animated)
    }

    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default does nothing
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

    // MARK: - Notifications

    /// Animate bottom constraint when keyboard show or hide.
    @objc open func keyboardChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt,
            let keyboardEndFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)

        bottomLayoutConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY + 20
        let animationCurve = UIViewKeyframeAnimationOptions(rawValue: curve)

        UIView.animateKeyframes(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    // MARK: - Get info

    /// Return the email from `loginTextField`.
    open var email: String {
        return self.loginTextField.text ?? ""
    }

    /// Return any custom informations that must be send when authenticate.
    open var customParameters: [String: Any]? {
        return [:]
    }

    /// Function called when email change.
    @IBAction open func loginTextDidChange(_ sender: Any) {
        if checkLoginClickable() {
            loginTextField.errorMessage = ""
        } else {
            if email.count > 3 && !email.isValidEmail {
                loginTextField.errorMessage = "Invalid email"
            } else {
                loginTextField.errorMessage = ""
            }
        }
    }

    /// Check if login button must be clickable. Using `isLoginClickable`.
    /// If `false` the button interaction is disabled.
    open func checkLoginClickable() -> Bool {
        let value = isLoginClickable
        loginButton.isUserInteractionEnabled = value
        return value
    }

    // MARK: - Actions

    /// Respond if email is valid or not to login with.
    /// Could be overriden to add custom logic like specific emails pattern.
    open var isLoginClickable: Bool {
        return email.isValidEmail
    }

    @IBAction open func login(_ sender: Any!) {
        let email = self.email
        let parameters = self.customParameters

        if isLoginClickable {
            loginButton.startAnimation()
            loginTextField.isEnabled = false
            cancellable = APIManager.instance.authentificate(login: email, parameters: parameters) {  [weak self] result in
                guard let this = self else { return }
                switch result {
                case .success(let token):
                    this.loginButton.stopAnimation {
                        DispatchQueue.main.async {
                            this.loginTextField.isEnabled = true
                            this.performSegue(withIdentifier: this.loggedSegueIdentifier, sender: sender)
                        }
                    }

                    if let statusText = token.statusText {
                        onForeground {
                          SwiftMessages.displayConfirmation(statusText)
                        }
                    }
                case .failure(let error):
                    logger.warning("Failed to login: \(error)")
                    this.loginButton.stopAnimation()
                    this.loginButton.reset()
                    this.loginTextField.isEnabled = true
                    this.loginTextField.shake()

                    onForeground {
                        if let restError = error.restErrors {
                            if let statusText = restError.statusText {
                                SwiftMessages.displayError(title: error.errorDescription ?? "Failed to login", message: statusText)
                            }
                        }
                    }
                }
            }
        } else {
            self.loginTextField.shake()
        }
    }

    @IBAction open func cancel(_ sender: Any!) {
        cancel()
    }

    func cancel() {
        cancellable?.cancel()
        // XXX maybe reset ui component
    }

}
