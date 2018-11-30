//
//  SettingReloadCell.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit

import Moya
import Prephirences
import SwiftMessages

import QMobileAPI
import QMobileDataSync

open class SettingReloadCell: UITableViewCell {

    @IBOutlet open weak var reloadButton: UIButton!
    var cancellable: Cancellable?

    static let maxRetryCount = 2
    var tryCount = 0
    private var stopBlock: () -> Void = {}

    open override func awakeFromNib() {
        ServerStatusManager.instance.add(listener: self)
    }

}

extension SettingReloadCell: ServerStatusListener {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            // Activate reload button if status is ok
            self.reloadButton.isEnabled = status.isSuccess
        }
    }

}

// MARK: action on dialog button press

extension SettingReloadCell: DialogFormDelegate {

    // if ok pressed
    public func onOK(dialog: DialogForm, sender: Any) {
        if let button = sender as? LoadingButton {
            button.startAnimation()
        }
        stopBlock = {
            if let button = sender as? LoadingButton {
                button.stopAnimation()
            }
            dialog.dismiss(animated: true)
            ServerStatusManager.instance.checkStatus(0) // XXX do elsewhere (break using listener)
        }
        tryCount = 1
        cancellable = DataReloadManager.instance.reload(didReload)
    }

    // if cancel pressed
    public func onCancel(dialog: DialogForm, sender: Any) {
        cancellable?.cancel()
        onForeground {
            dialog.dismiss(animated: true) /// XXX maybe wait cancel
        }
    }

    /// Return true if application need to display login form.
    /// see application preferences.

    public func logout(_ completion: (() -> Void)? = nil) {
        _ = APIManager.instance.logout { _ in
            foreground {
                self.viewController?.performSegue(withIdentifier: "logout", sender: self)
                completion?()
            }
        }
    }

    /// Called when reload end.
    public func didReload(_ result: DataSync.SyncResult) {
        var didEnd = true
        switch result {
        case .success:
            SwiftMessages.info("Data has been reloaded")
        case .failure(let error):
            let title = "Issue when reloading data"
            if error.mustRetry {
                if Prephirences.Auth.withForm {
                    // Display error before logout
                    SwiftMessages.error(title: error.errorDescription ?? title,
                                        message: error.mustRetryMessage,
                                        configure: configure())
                } else {
                    _ = APIManager.instance.authentificate(login: "") { result in
                        switch result {
                        case .success:
                            // retry XXX manage it elsewhere with a request retrier
                            if self.tryCount < SettingReloadCell.maxRetryCount {
                                didEnd = false
                                self.tryCount += 1
                                _ = DataReloadManager.instance.reload(self.didReload)
                            }
                        case .failure(let authError):
                            if let statusText = authError.restErrors?.statusText {
                                SwiftMessages.error(title: error.errorDescription ?? title, message: statusText)
                            } else {
                                SwiftMessages.error(title: error.errorDescription ?? title, message: error.failureReason ?? "")
                            }
                        }
                    }
                }
            } else {
                SwiftMessages.error(title: error.errorDescription ?? title, message: error.failureReason ?? "")
            }
        }

        if didEnd {
            onForeground(stopBlock)
        }
    }

    // Configure logout dialog and action
    fileprivate func configure() -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = { _ in
                SwiftMessages.hide()
                self.logout()
            }
            var config = config
            config.presentationStyle = .center
            config.duration = .forever
            // no interactive because there is no way yet to get background tap handler to make logout
            config.dimMode = .gray(interactive: false)
            return config
        }
    }

}

extension DataSyncError {

    fileprivate var mustRetry: Bool {
        if case .apiError(let apiError) = self {
            if apiError.isHTTPResponseWith(code: .unauthorized) {
                return true
            }
            if let restErrors = apiError.restErrors, restErrors.match(.query_placeholder_is_missing_or_null) {
                return true
            }
        }
        return false
    }

    fileprivate var mustRetryMessage: String {
        if case .apiError(let apiError) = self {
            if apiError.isHTTPResponseWith(code: .unauthorized) {
                return "You have been disconnected"
            }
            if let restErrors = apiError.restErrors, restErrors.match(.query_placeholder_is_missing_or_null) {
                return "You need to reconnect to reload."
            }
        }
        return ""
    }

}
