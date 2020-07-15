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
public protocol LoginFormDelegate: NSObjectProtocol {
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
    @IBOutlet open weak var loginButton: UIButton!
    /// The text field for the login information ie. the email.
    @IBOutlet open weak var loginTextField: UITextField!

    /// The current action of login ie. the process cancellable.
    public var logInAction: Cancellable?

    public weak var delegate: LoginFormDelegate?

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()

        initLoginInformation()
        loginTextField.delegate = self
        _ = checkLoginClickable()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // observe keyboard for bottom change
        registerKeyboard()
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

    ///  Called before `onWillLogin` to stop login process.
    ///  By default if email invalid. Display an error, and stop login.
    /// - return `true` if login could start.
    open func couldLogin() -> Bool {
        guard email.isValidEmail else {
            displayInputError(message: "Invalid Email")
            self.loginTextField.shake()
            return false
        }
        return true
    }

    // MARK: - Notifications

    func registerKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    func unresisterKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    /// Notification about keyboard. Allow to move graphic elements, for instance constraintes.
    @objc open func keyboardChanged(_ notification: NSNotification) {
        update(constraint: bottomLayoutConstraint, with: notification )
    }

    /// Animate bottom constraint when keyboard show or hide.
    open func update(constraint: NSLayoutConstraint, with notification: NSNotification) {
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

    /// Return the email, by default from `loginTextField`.
    open var email: String {
        return self.loginTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Return any custom informations that must be send when authenticate.
    open var customParameters: [String: Any]? {
        return [:]
    }

    /// Function called when email text field change.
    @IBAction open func loginTextDidChange(_ sender: Any) {
        var errorMessage = ""
        if !checkLoginClickable() {
           errorMessage = loginNotClickableMessage() ?? errorMessage
        }
        displayInputError(message: errorMessage)
    }

    /// Optionnal message to display if not email not clickable. By default nothing.
    open func loginNotClickableMessage() -> String? {
        /*let email = self.email
        if email.count > 3 && !email.isValidEmail {
           return "Invalid email"
        }*/
        return nil
    }

    /// Display the input error message such as "Invalid email". By default if text field is floating label,
    open func displayInputError(message: String) {
        if var errorLabel = loginTextField as? ErrorMessageableTextField {
            errorLabel.errorMessage = message
        }
    }

    /// When starting fill email with stored one.
    /// Could override to store other parameters.
    open func initLoginInformation() {
        if let email = Prephirences.Auth.Login.email {
            loginTextField.text = email
        }
    }

    /// Save login email when clicking login button.
    open func storeLoginInformation() {
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

    /// Respond if login button clicable or not.
    /// Could be overriden to add custom logic like specific emails pattern.
    /// - returns : true by efault if email not empty.
    open var isLoginClickable: Bool {
        return !email.isEmpty
    }

    fileprivate func startLoginUI() {
        (loginButton as? QAnimatableButton)?.startAnimation()
        loginTextField.isEnabled = false
    }

    fileprivate func stopLoginUI(completion: @escaping () -> Void) {
        onForeground {
            if let button = self.loginButton as? QAnimatableButton {
                button.stopAnimation {
                    self.loginTextField.isEnabled = true
                    self.loginTextField.becomeFirstResponder()
                    completion()
                }
            } else {
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

    /// Log login result.
    public func log(_ result: (Result<AuthToken, APIError>)) {
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

    /// On login, displayed error if needed, call delegate and perform transition if authentification success.
    public func manageLoginResult(_ result: Result<AuthToken, APIError>, _ sender: Any?) {
        self.onDidLogin(result: result)

        let consumed = self.delegate?.didLogin(result: result) ?? false
        // Display message
        if !consumed {
            self.display(result: result)
        }

        // If success, transition (otherway to do that, ask a delegate to do it)
        switch result {
        case .success(let token):
            if token.isValidToken {
                self.performTransition(sender)
            }
        case .failure:
            break
        }
    }

    fileprivate func doLogin(_ sender: Any?) {
        let startDate = Date() // keep start date
        onWillLogin() // Called after the view has been loaded. Default does nothing
        startLoginUI() // Start UI animation
        storeLoginInformation()

        logInAction = APIManager.instance.authentificate(login: self.email, parameters: self.customParameters) {  [weak self] result in
            guard let this = self else { return }

            this.log(result)

            // Then sleep a little before stop login ui
            Thread.sleep(until: startDate + 1) // allow to start animation if server respond to quickly

            this.stopLoginUI {
                this.manageLoginResult(result, sender)
            }
        }
    }

    // MARK: IBAction

    /// Login action linked to the login button.
    @IBAction open func login(_ sender: Any!) {
        guard couldLogin() else {
            return
        }

        doLogin(sender)
    }

    @IBAction open func cancel(_ sender: Any!) {
        cancelLogIn()
    }

    // MARK: Server

    fileprivate var serverPrefererences: MutablePreferencesType {
        return UserDefaults.standard
    }

    /// Allow to change current server URL config before login.
    open var serverURL: String? {
        get {
            let preference = serverPrefererences
            return preference["server.url"] as? String
        }
        set {
            var preference = serverPrefererences
            preference["server.url"] = newValue
            preference["server.url.edited"] = true
            APIManager.instance = APIManager(url: URL.qmobile)
            DataSync.instance.apiManager = APIManager.instance
        }
    }

}

extension LoginForm: DeepLinkable {
    public var deepLink: DeepLink? { return .login }
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
