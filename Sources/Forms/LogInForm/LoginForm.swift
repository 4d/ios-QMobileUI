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
import Result

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

    /// The current action of login ie. the process cancellable.
    var logInAction: Cancellable?

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()

        initLoginText()
        loginTextField.delegate = self
        _ = checkLoginClickable()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // objserve keyboard for bottom change
        registerKeyboard()
        // login field is selected
        loginTextField.becomeFirstResponder()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // By default to not allow to log XXX maybe already done by viewDidLoad
        loginButton.isUserInteractionEnabled = false

        // login field is selected
        loginTextField.becomeFirstResponder()
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unresisterKeyboard()
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

    func registerKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    func unresisterKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc open func keyboardChanged(_ notification: NSNotification) {
        update(constraint: bottomLayoutConstraint, with: notification )
    }

    /// Animate bottom constraint when keyboard show or hide.
    func update(constraint: NSLayoutConstraint, with notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)

        constraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY + 20
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
            }
        }
    }

    open func initLoginText() {
        if let login = Prephirences.sharedInstance["auth.login"] as? String {
            loginTextField.text = login
        }
    }

    fileprivate func saveLoginText() {
        if saveLoginInfo {
            var pref = Prephirences.sharedMutableInstance
            pref?["auth.login"] = email
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

    fileprivate func startLoginUI() {
        loginButton.startAnimation()
        loginTextField.isEnabled = false
    }

    fileprivate func stopLoginUI(completion: @escaping () -> Void) {
        onForeground {
            self.loginButton.stopAnimation {
                self.loginButton.reset()
                self.loginTextField.isEnabled = true

                completion()
            }
        }
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

    fileprivate func displayStatusText(_ token: (AuthToken)) {
        if let statusText = token.statusText, !statusText.isEmpty {
            // Maybe some issues with displaying during segue
            SwiftMessages.info(statusText)
        }
    }

    /// After authentification, log change UI, display status or error.
    func manageAuthentificationResult(_ result: Result<AuthToken, APIError>, sender: Any!) {
        switch result {
        case .success(let token):
            logger.info("Application has been authenticated.")
            self.performSegue(withIdentifier: self.loggedSegueIdentifier, sender: sender)
            self.displayStatusText(token)

            if Prephirences.Auth.reloadData {
                DataReloadManager.instance.reload { result in
                    switch result {
                    case .success:
                        SwiftMessages.info("Data has been reloaded")
                    case .failure(let error):
                        let title = "Issue when reloading data"
                        // Display error before logout
                        SwiftMessages.error(title: error.errorDescription ?? title,
                                            message: error.failureReason ?? "",
                                            configure: self.configure())
                    }
                }
            }

        case .failure(let error):
            logger.warning("Failed to login: \(error)")
            self.displayError(error)
            self.loginTextField.becomeFirstResponder()
        }
    }
    // Configure logout dialog and action
    fileprivate func configure() -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = { _ in
                SwiftMessages.hide()
            }
            var config = config
            config.presentationStyle = .center
            config.duration = .forever
            // no interactive because there is no way yet to get background tap handler to make logout
            config.dimMode = .gray(interactive: false)
            return config
        }
    }
    /// Cancel the login.
    func cancelLogIn() {
        logInAction?.cancel()
        // XXX maybe reset ui component
    }

    fileprivate func logIn(_ sender: Any?) {
        let startDate = Date() // keep start date
        // Start UI animation
        startLoginUI()
        saveLoginText()
        logInAction = APIManager.instance.authentificate(login: self.email, parameters: self.customParameters) {  [weak self] result in
            guard let this = self else { return } // memory

            Thread.sleep(until: startDate + 1) // allow to start animation if server respond to quickly

            this.stopLoginUI {
                this.manageAuthentificationResult(result, sender: sender)
            }
        }
    }

    // MARK: IBAction

    @IBAction open func login(_ sender: Any!) {
        // if click but not available -> shake
        guard isLoginClickable else {
            self.loginTextField.shake()
            return
        }

        logIn(sender)
    }

    @IBAction open func cancel(_ sender: Any!) {
        cancelLogIn()
    }

}
