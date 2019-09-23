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

/// Delegate for login form
protocol LoginFormDelegate: NSObjectProtocol {
    /// Result of login operation.
    func didLogin(result: Result<AuthToken, APIError>) -> Bool
}

/// Form to login
@IBDesignable
open class LoginForm: UIViewController, UITextFieldDelegate, Form {

    /// If true save login information and fill it at start.
    @IBInspectable open var saveLoginInfo: Bool = Prephirences.Auth.Login.save

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

    weak var delegate: LoginFormDelegate?

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

        _ = checkLoginClickable()

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

    /// Function call before launch standard login.
    open func onWillLogin() {}
    /// Function after launching login process.
    open func onDidLogin(result: Result<AuthToken, APIError>) {}

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
        if let email = Prephirences.Auth.Login.email {
            loginTextField.text = email
        }
    }

    fileprivate func saveLoginText() {
        if saveLoginInfo {
            Prephirences.Auth.Login.email = email
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

                self.loginTextField.becomeFirstResponder()
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

            if error.isServerCertificateError {
                SwiftMessages.error(title: "Server certificate error. Please advice the server administrator.",
                                    message: error.localizedDescription)
            } else {
                SwiftMessages.warning(error.localizedDescription, configure: { _, config in
                    /*view.tapHandler = { _ in
                        // XXX maybe allow to configure server url
                    }*/
                    return config
                })
            }
        } else if let error = error.afError {
            switch error {
            case .responseValidationFailed(let reason):
                switch reason {
                case .unacceptableStatusCode(let code):
                    if code == 401 {
                        SwiftMessages.warning("You are not authorized")
                        return
                    }
                default:
                    break
                }
                return
            case .sessionTaskFailed(let error):
                SwiftMessages.warning(error.localizedDescription)
                return
            default:
                break
            }
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

    fileprivate func display(result: Result<AuthToken, APIError>) {
        switch result {
        case .success(let token):
            self.displayStatusText(token)
        case .failure(let error):
            self.displayError(error)
        }
    }

    /// Use the `Segue` to make the transition, otherwise instanciate hard coded transition.
    open var performSegue = true

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.fix()
    }

    /// Cancel the login.
    func cancelLogIn() {
        logInAction?.cancel()
        // XXX maybe reset ui component
    }

    fileprivate func log(_ result: (Result<AuthToken, APIError>)) {
        switch result {
        case .success(let token):
            if token.isValidToken {
                logger.info("Application has been authenticated with \(String(describing: token.email)).")
            } else {
                logger.info("Application has been authenticated with \(String(describing: token.email)) but no valid token returned. Maybe session must be verified.")
            }
        case .failure(let error):
            logger.warning("Failed to login: \(error)")
        }
    }

    fileprivate func doLogin(_ sender: Any?) {
        let startDate = Date() // keep start date
        onWillLogin() // Called after the view has been loaded. Default does nothing
        startLoginUI() // Start UI animation
        saveLoginText()
        logInAction = APIManager.instance.authentificate(login: self.email, parameters: self.customParameters) {  [weak self] result in
            guard let this = self else { return }

            this.log(result)

            // Then sleep a little before stop login ui
            Thread.sleep(until: startDate + 1) // allow to start animation if server respond to quickly

            this.stopLoginUI {
                this.onDidLogin(result: result)

                let consumed = this.delegate?.didLogin(result: result) ?? false
                // Display message
                if !consumed {
                    this.display(result: result)
                }

                // If success, transition (otherway to do that, ask a delegate to do it)
                switch result {
                case .success(let token):
                    if token.isValidToken {
                        this.performTransition(sender)
                    }
                case .failure:
                    break
                }
            }
        }
    }

    // MARK: IBAction

    /// Login action linked to the login button.
    @IBAction open func login(_ sender: Any!) {
        // if click but not available -> shake
        guard isLoginClickable else {
            self.loginTextField.shake()
            return
        }

        doLogin(sender)
    }

    @IBAction open func cancel(_ sender: Any!) {
        cancelLogIn()
    }

}

private let serverCertificateCodes: [URLError.Code] = [
    .serverCertificateHasBadDate,
    .serverCertificateHasUnknownRoot,
    .serverCertificateNotYetValid,
    .serverCertificateUntrusted
]

extension URLError {

    /// Return true if this is an server certificate error.
    var isServerCertificateError: Bool {
        return serverCertificateCodes.contains(self.code)
    }
}
