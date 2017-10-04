//
//  SettingsServerSectionFooter.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 06/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileAPI
import QMobileDataSync

import IBAnimatable
import Prephirences
import Moya
import Result

public protocol SettingsServerSectionFooterDelegate: NSObjectProtocol {
    func onStatusChanged(status: ServerStatus)
}

open class SettingsServerSectionFooter: UITableViewHeaderFooterView, UINibable, ReusableView {

    @IBOutlet weak open var iconView: AnimatableView!
    @IBOutlet weak open var iconAnimationView: AnimatableActivityIndicatorView!
    @IBOutlet weak open var titleLabel: UILabel!
    @IBOutlet weak open var detailLabel: UILabel!
    /// Queue for checking
    let queue: OperationQueue = {
        let operationQueue = OperationQueue()

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility

        return operationQueue
        }()

    // install tap gesture
    public final override func awakeFromNib() {
        super.awakeFromNib()

        self.installTagGesture()

        serverStatus = .unknown
    }

    // Install tap gesture on footer to relaunch server status check
    // Override it and do nothing remote it
    open func installTagGesture() {
        let gestureRecognizer =  UITapGestureRecognizer(target: nil, action: #selector(self.tapped(_:)))
        self.iconView.addGestureRecognizer(gestureRecognizer)
        self.iconView.isUserInteractionEnabled = true
        self.titleLabel.addGestureRecognizer(gestureRecognizer)
        self.titleLabel.isUserInteractionEnabled = true
    }

    func tapped(_ sender: UITapGestureRecognizer) {
        checkStatus(2)
    }

    // MARK: status

    /// Current status
    public private(set) var serverStatus: ServerStatus = .unknown {
        didSet {
            updateUI()
        }
    }
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
       // queue.waitUntilAllOperationsAreFinished() // bad, do not wait on main thread

        // Start checking in a new task

        let checkingUUID = UUID().uuid
        self.queue.addOperation {
            //logger.verbose("Checking status \(checkingUUID). sleep start")
            //Thread.sleep(forTimeInterval: delay)
            //logger.verbose("Checking status \(checkingUUID). sleep end")
        }
        self.queue.addOperation {
            self.serverStatus(.checking)
            logger.verbose("Checking status \(checkingUUID). load status start")
            let apiManager = APIManager(url: url)
            let checkstatus = apiManager.loadStatus()
            let context = self.queue.context
            checkstatus.onSuccess(context) { _ in
                APIManager.instance = apiManager
                DataSync.instance.rest = apiManager
            }
            checkstatus.onComplete(context) { [weak self] result in
                self?.serverStatus(.done(result))
                logger.verbose("Checking status \(checkingUUID). load status end")
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
        onForeground { // ui code must be done in main thread
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

open class ServerStatusView: AnimatableActivityIndicatorView {}
