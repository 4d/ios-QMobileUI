//
//  ServerStatusManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences
import Moya

import BrightFutures

import QMobileAPI
import QMobileDataSync

public protocol ServerStatusListener: NSObjectProtocol {
    func onStatusChanged(status: ServerStatus)
}

open class ServerStatusManager {

    static let instance = ServerStatusManager()

    var listeners: [ServerStatusListener] = []

    /// Queue for checking
    public let queue: OperationQueue = {
        let operationQueue = OperationQueue()

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility

        return operationQueue
    }()

    public private(set) var serverStatus: ServerStatus = .unknown {
        didSet {
            updateListener()
        }
    }

    open func updateListener() {
        for listener in listeners {
            listener.onStatusChanged(status: serverStatus)
        }
    }

    open func add(listener: ServerStatusListener) {
        listener.onStatusChanged(status: serverStatus)
        self.listeners.append(listener)
    }

    /// Check the server status
    open func checkStatus(_ delay: TimeInterval = 0) {
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

        let checkingUUID = UUID()
        self.queue.addOperation {
            //logger.verbose("Checking status \(checkingUUID). sleep start")
            //Thread.sleep(forTimeInterval: delay)
            //logger.verbose("Checking status \(checkingUUID). sleep end")
        }
        self.queue.addOperation {
            self.serverStatus(.checking)
            logger.debug("Checking server status \(url) \(checkingUUID) start")
            let apiManager = APIManager(url: url)

            let checkstatus = apiManager.status()
            let context = self.queue.context
            checkstatus.onComplete(context) { [weak self] result in
                self?.serverStatus(.done(result))
                logger.debug("Checking status \(url) \(checkingUUID) end: \(result)")
                APIManager.instance = apiManager
                DataSync.instance.apiManager = apiManager
            }
        }
    }

    private func serverStatus(_ status: ServerStatus) {
        // let oldStatus = self.serverStatus // XXX if too much notif, use old status to notify or not
        self.serverStatus = status

        updateListener()
    }

}
