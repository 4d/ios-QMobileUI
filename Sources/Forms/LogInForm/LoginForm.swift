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
open class LoginForm: UIViewController, UITextFieldDelegate {

    /// Identifier for segue when successfuly logged. Default value "logged"
    @IBInspectable open var loggedSegueIdentifier: String = "logged"

    /// If true save login information and fill it at start.
    @IBInspectable open var saveLoginInfo: Bool = false

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

        if let login = Prephirences.sharedInstance["auth.login"] as? String {
            loginTextField.text = login
        }
        loginTextField.delegate = self
        _ = checkLoginClickable()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        loginTextField.becomeFirstResponder()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginButton.isUserInteractionEnabled = false
        loginTextField.becomeFirstResponder()
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)

        bottomLayoutConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY + 20
        let animationCurve = UIView.KeyframeAnimationOptions(rawValue: curve)

        UIView.animateKeyframes(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    // MARK: - Get info

    /// Return the email from `loginTextField`.
    open var email: String {
        return self.loginTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
            let email = self.email
            if email.count > 3 && !email.isValidEmail {
                loginTextField.errorMessage = "Invalid email"
            } else {
                loginTextField.errorMessage = ""

                if saveLoginInfo {
                    var pref = Prephirences.sharedMutableInstance
                    pref?["auth.login"] = email
                }
            }
        }
    }

    /// The login text field is no more edited.
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField.resignFirstResponder() // Dismiss the keyboard
        login(textField)
        return true
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

    fileprivate func updateUIForLogin() {
        loginButton.startAnimation()
        loginTextField.isEnabled = false
    }

    fileprivate func displayError(_ error: (APIError)) {
        if let restError = error.restErrors {
            if let statusText = restError.statusText {
                SwiftMessages.warning(statusText)
            } else {
                SwiftMessages.warning("You are not allowed to connect.")
            }
            self.loginTextField.shake()
        } else if let error = error.urlError {
            let serverCertificateCodes: [URLError.Code] = [
                .serverCertificateHasBadDate,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .serverCertificateUntrusted
            ]
            if serverCertificateCodes.contains(error.code) {
                SwiftMessages.error(title: "Server certificate error. Please advice the server administrator.",
                                    message: error.localizedDescription)
            } else {
                SwiftMessages.warning(error.localizedDescription)
            }
        } else if let error = error.afError {
            SwiftMessages.warning(error.localizedDescription)
        } else if let error = error.moyaError {
            SwiftMessages.warning(error.localizedDescription)
        }
    }

    @IBAction open func login(_ sender: Any!) {
        guard isLoginClickable else {
            self.loginTextField.shake()
            return
        }
        let date = Date() + 1
        updateUIForLogin()
        cancellable = APIManager.instance.authentificate(login: self.email, parameters: self.customParameters) {  [weak self] result in
            guard let this = self else { return }

            Thread.sleep(until: date) // allow to start animation if server respond to quickly

            onForeground {
                this.loginButton.stopAnimation {
                    this.loginButton.reset()
                    this.loginTextField.isEnabled = true

                    switch result {
                    case .success(let token):
                        logger.warning("Application has been authenticated.")
                        this.performSegue(withIdentifier: this.loggedSegueIdentifier, sender: sender)

                        if let statusText = token.statusText, !statusText.isEmpty {
                            // Maybe some issues with displaying during segue
                            SwiftMessages.info(statusText)
                        }

                    case .failure(let error):
                        logger.warning("Failed to login: \(error)")

                        this.displayError(error)

                        this.loginTextField.becomeFirstResponder()
                    }

                }
            }
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
