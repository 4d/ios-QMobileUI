//
//  SettingsServerSectionFooter.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 06/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileUI
import QMobileAPI
import QMobileDataSync

import IBAnimatable
import Prephirences
import Moya
import Result

public protocol SettingsServerSectionFooterDelegate: NSObjectProtocol {
    func onStatusChanged(status: ServerStatus)
}

public class SettingsServerSectionFooter: UITableViewHeaderFooterView, UINibable, ReusableView {

    @IBOutlet weak var iconView: AnimatableView!
    @IBOutlet weak var iconAnimationView: AnimatableActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    // install tap gesture
    public override func awakeFromNib() {
        super.awakeFromNib()

        self.installTagGesture()
    }

    private func installTagGesture() {
        let gestureRecognizer =  UITapGestureRecognizer(target: nil, action: #selector(self.tapped(_:)))
        self.iconView.addGestureRecognizer(gestureRecognizer)
        self.titleLabel.addGestureRecognizer(gestureRecognizer)
    }

    func tapped(_ sender: UITapGestureRecognizer) {
        checkStatus(2)
    }

    // MARK: status

    /// Current status
    var serverStatus: ServerStatus = .unknown
    /// Queue for check
    let queue = OperationQueue(underlyingQueue: .background)
    /// Delegate to notify server status change
    weak var delegate: SettingsServerSectionFooterDelegate?

    /// Check the server status
    func checkStatus(_ delay: TimeInterval = 0) {
        guard let text = Prephirences.serverURL, !text.isEmpty else {
            serverStatus(.emptyURL)
            return
        }
        guard var url = URL(string: text) else {
            serverStatus(.notValidURL)
            return
        }

        // Check URL validity
        if url.scheme == nil { // be kind, add scheme
            url = URL(string: "\(URL.defaultScheme)://\(text)") ?? url
        }
        guard url.isHttpOrHttps else {
            serverStatus(.notValidScheme)
            return
        }

        // Cancel all previous checking status
        queue.cancelAllOperations()
        queue.waitUntilAllOperationsAreFinished()

        // Start checking in a new task
        self.serverStatus(.checking)
        self.queue.addOperation {
            let apiManager = APIManager(url: url)
            let checkstatus = apiManager.loadStatus()
            checkstatus.onSuccess(self.queue.context) { _ in
                APIManager.instance = apiManager
                DataSync.instance.rest = apiManager
            }
            checkstatus.onComplete(self.queue.context) { [weak self] result in
                self?.serverStatus(.done(result))
            }
        }
    }

    private func serverStatus(_ status: ServerStatus) {
        let oldStatus = self.serverStatus
        self.serverStatus = status

        updateUI()

        // Notify delegqte
        if oldStatus != status {
            delegate?.onStatusChanged(status: status)
        }
    }

    private func updateUI() {
        onForeground {
            self.iconView.backgroundColor = self.serverStatus.color
            self.titleLabel.text = self.serverStatus.message
            self.detailLabel.text = self.serverStatus.detailMessage

            if self.serverStatus.isChecking {
                self.iconAnimationView.startAnimating()
            } else {
                self.iconAnimationView.stopAnimating()
            }
        }
    }

}

public class ServerStatusView: AnimatableActivityIndicatorView {}
