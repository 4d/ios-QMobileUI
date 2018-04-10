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

import QMobileAPI
import QMobileDataSync

/// Form to login
@IBDesignable
open class LoginForm: UIViewController {

    /// Segue to go to passcode form
    @IBInspectable open var passcodeSegueIdentifier: String = "passcode"

    var cancellable: Cancellable?

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    // MARK: functions

    /// Check content of loginTextField to login ie. valid email.
    open func isValid(login: String) -> Bool {
        return login.isValidEmail
    }

    /// Function to return user login
    open func loginText() -> String? {
        assertionFailure("Login text must be provided by form")
        return nil
    }

    /// Return additional parameters to send to authentification process
    open func customLoginParameters() -> [String: Any]? {
        return nil
    }

    // MARK: Action

    /// Action when pushing login
    @IBAction open func login(_ sender: Any?) {

        guard let login = loginText(), !login.isEmpty else {
            // Maybe shake the loginTextField
            alert(title: "Login field must not be empty.")
            return
        }

        guard isValid(login: login) else {
            // Maybe shake the loginTextField
            alert(title: "Login field must be valid email.")
            return
        }

        let rest = ApplicationDataSync.dataSync.rest
        cancellable = rest.authentificate(login: login, parameters: customLoginParameters()) { result in

            switch result {
            case .success(let authToken):
                // Go to passcode view
                assert(authToken.isValid) // status could contains additionnal info
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: self.passcodeSegueIdentifier, sender: sender)
                }
            case .failure(let error):
                // TODO Auth ; according to error notify user
                // email not accepted, custom message from server
                // Server failed to send a mail
                alert(title: "Failed to authentificate", message: error.localizedDescription)
            }
        }
    }

    @IBAction open func cancelLogin(_ sender: Any?) {
        cancellable?.cancel()
    }

}
