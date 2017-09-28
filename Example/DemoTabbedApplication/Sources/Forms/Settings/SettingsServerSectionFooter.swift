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
    func statusChanged(status: ServerStatus)
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
            url = URL(string: "http://\(text)") ?? url
        }
        if url.host?.isEmpty ?? false {
            serverStatus(.notValidURL)
            return
        }
        guard url.isHttpOrHttps else {
            serverStatus(.notValidURL)
            return
        }

        // Start checking
        queue.cancelAllOperations()
        queue.waitUntilAllOperationsAreFinished()
        background(delay) {
            DispatchQueue.main.sync {
                self.serverStatus(.checking)
            }
            self.queue.waitUntilAllOperationsAreFinished()
            self.queue.addOperation {
                let apiManager = APIManager(url: url)
                let checkstatus = apiManager.loadStatus(callbackQueue: .background)
                checkstatus.onSuccess(.main) { _ in
                    DataSync.instance.rest = APIManager.instance
                }
                checkstatus.onComplete { [weak self] result in
                     self?.serverStatus(.done(result))
                }

                /*checkstatus.onComplete { result in
                    apiManager.reachability { _ in
                        self.checkStatus(10)
                        }.flatMap { self.cancellables.append($0) }
                }*/
            }
        }
    }

    private func serverStatus(_ status: ServerStatus) {
        let oldStatus = self.serverStatus
        self.serverStatus = status

        updateUI()

        // Notify delegqte
        if oldStatus != status {
            delegate?.statusChanged(status: status)
        }
    }

    private func updateUI() {
        self.iconView.backgroundColor = serverStatus.color
        self.titleLabel.text = serverStatus.message
        self.detailLabel.text = serverStatus.detailMessage

        foreground {
            if self.serverStatus.isChecking {
                self.iconAnimationView.startAnimating()
            } else {
                self.iconAnimationView.stopAnimating()
            }
        }
    }

}

public class ServerStatusView: AnimatableActivityIndicatorView {

}
