//
//  SettingURLForm.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 12/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences
import QMobileAPI
import QMobileDataSync
import DeviceKit

open class SettingURLForm: UIViewController, Storyboardable {

    @IBOutlet open weak var serverURLTextField: UITextField!
    @IBOutlet open weak var connectButton: UIButton!

    fileprivate var status: ServerStatus = .unknown

    /// Constaint for view at the bottom.
    @IBOutlet weak open var bottomLayoutConstraint: NSLayoutConstraint!

    // MARK: events
    final public override func viewDidLoad() {
        super.viewDidLoad()

        // Listen to textfield change
        serverURLTextField.addTarget(self, action: #selector(onDataChanged(textField:)), for: .editingChanged)
        onLoad()
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear(animated)
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboard()
        ServerStatusManager.instance.add(listener: self)
        serverURLTextField.becomeFirstResponder()
        _ = checkClickable()
        onWillAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        ServerStatusManager.instance.remove(listener: self)
        onWillDisappear(animated)
        unresisterKeyboard()
        super.viewWillDisappear(animated)
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

    @objc open func onDataChanged(textField: UITextField) {
        // check connect button clickable
        _ = checkClickable()
        // remove error message
        if var errorLabel = serverURLTextField as? ErrorMessageableTextField {
            errorLabel.errorMessage = nil
        }
        // check status of server now
        self.updateServerURL(save: false)
        ServerStatusManager.instance.checkStatus(2)
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

    // MARK: action
    /*@IBAction open func serverURLTextFieldEndEditing(_ sender: Any?) {
        self.serverURLTextField.endEditing(true)
    }*/

    func message(_ message: String) {
        logger.info(message)

    }

    @IBAction open func connect(_ sender: Any?) {
        startLoginUI()
        let startDate = Date() // keep start date

        DispatchQueue.main.async {
            self.updateServerURL(save: true)
            self.message("Checking server")
            _ = APIManager.instance.status { [weak self] result in
                Thread.sleep(until: startDate + 1) // allow to start animation if server respond to quickly
                self?.message("Connected to server")
                switch result {
                case .success:
                    Prephirences.Reset.serverAddress = false
                    APIManager.instance.authToken = nil
                    self?.message("Creating initial data...")
                    ApplicationDataStore.instance.dropAndLoad { newDataStore in
                        self?.message("Data loaded")
                        ApplicationDataSync.instance.dataSync.dataStore = newDataStore
                        self?.stopLoginUI {
                            DispatchQueue.main.async {
                                self?.presentingViewController?.dismiss(animated: false, completion: nil)
                            }
                        }
                    }
                case .failure(let error):
                    self?.stopLoginUI {
                        if var errorLabel = self?.serverURLTextField as? ErrorMessageableTextField {
                            errorLabel.errorMessage = self?.status.message
                        }
                        logger.info("connection error \(error)")
                    }
                }
            }
        }
    }

    fileprivate var serverPrefererences: MutablePreferencesType {
        return UserDefaults.standard
    }

    // MARK: server
    open func checkClickable() -> Bool {
        let value = isClickable
        connectButton.isUserInteractionEnabled = value
        return value
    }

    open var isClickable: Bool {
        return !serverURL.isEmpty
    }

    var serverURL: String {
        guard var value = self.serverURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return ""
        }
        if !value.hasPrefix("http") {
            value = "https://"+value
        }
        return value
    }

    fileprivate func updateServerURL(save: Bool = false) {
        var preference = serverPrefererences
        preference["server.url"] = self.serverURL
        if save {
            preference["server.url.edited"] = true
            APIManager.instance = APIManager(url: URL.qmobile)
            DataSync.instance.apiManager = APIManager.instance
        }
    }

    // MARK: 
    fileprivate func startLoginUI() {
        (connectButton as? QAnimatableButton)?.startAnimation()
        serverURLTextField.isEnabled = false
    }

    fileprivate func stopLoginUI(completion: @escaping () -> Void) {
        onForeground {
            if let button = self.connectButton as? QAnimatableButton {
                button.stopAnimation {
                    self.serverURLTextField.isEnabled = true
                    self.serverURLTextField.becomeFirstResponder()
                    completion()
                }
            } else {
                self.serverURLTextField.isEnabled = true
                self.serverURLTextField.becomeFirstResponder()
                completion()
            }
        }
    }
}

extension SettingURLForm: ServerStatusListener {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            self.status = status
        }
    }

}
