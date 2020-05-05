//
//  ApplicationReachability.swift
//  QMobileUI
//
//  Created by Eric Marchand on 06/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Moya
import class Alamofire.NetworkReachabilityManager
import Prephirences
import BrightFutures

import QMobileAPI
import QMobileDataSync

/// Service to chek network avaibility and also configured server.
class ApplicationReachability: NSObject {

    var reachabilityTask: Cancellable?
    var reachabilityStatus: NetworkReachabilityStatus = .unknown

    var apiManagerObserver: NSObjectProtocol?
    var serverInfoTask: Cancellable?
    var serverInfo: WebTestInfo?
    var serverStatusTask: Cancellable?
    var serverStatus: Status?
}

// MARK: service
extension ApplicationReachability: ApplicationService {

    public static var instance: ApplicationService {
        return _instance
    }

    static let _instance = ApplicationReachability() // swiftlint:disable:this identifier_name

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        startMonitoringReachability()
        startMonitorigAPIManager()
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        stopMonitorigAPIManager()
        stopMonitoringReachability()
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        refreshServerInfo(APIManager.instance)
    }

}

// MARK: Reachability
extension ApplicationReachability {

    static var isReachable: Bool {
        return _instance.reachabilityStatus.isReachable
    }

    fileprivate func startMonitoringReachability() {
        //self.reachability = APIManager.instance.reachability { status in
        self.reachabilityTask = APIManager.reachability { status in
            self.reachabilityStatus = status
            switch status {
            case .reachable(let type):
                logger.debug("Server is reachable using \(type)")

            case .notReachable, .unknown:
                logger.debug("Server not reachable")
            }
        }
    }

    fileprivate func stopMonitoringReachability() {
        reachabilityTask?.cancel()
        reachabilityTask = nil
        reachabilityStatus = .unknown
    }

    fileprivate func startMonitorigAPIManager() {
        apiManagerObserver = APIManager.observe(APIManager.didChangeDefaultInstance) { [weak self] notification in
            guard let apiManager = notification.object as? APIManager else {
                return
            }
            guard apiManager === APIManager.instance else {
                return // maybe already changed too times
            }
            self?.refreshServerInfo(apiManager)
        }
    }
    fileprivate func stopMonitorigAPIManager() {
        serverInfoTask?.cancel()
        serverInfoTask = nil
        if let apiManagerObserver = apiManagerObserver {
            APIManager.unobserve(apiManagerObserver)
        }
        apiManagerObserver = nil
    }

    fileprivate func refreshServerInfo(_ apiManager: APIManager) {
        self.serverInfoTask = apiManager.loadWebTestInfo(callbackQueue: .background) {  [weak self] result in
            switch result {
            case .success(let serverInfo):
                logger.info("ServerInfo \(serverInfo)")
                self?.serverInfo = serverInfo
                self?.serverInfoTask = nil
            case .failure(let error):
                if ApplicationReachability.isReachable {
                    logger.warning("Error when getting server info \(error)")
                } else {
                    logger.debug("Error when getting server info \(error)")
                }
            }
        }

        self.serverStatusTask = apiManager.status { [weak self] result in
            switch result {
            case .success(let serverStatus):
                logger.info("ServerStatus \(serverStatus)")
                self?.serverStatus = serverStatus
                self?.serverStatusTask = nil
            case .failure(let error):
                if ApplicationReachability.isReachable {
                    logger.warning("Error when getting server status \(error)")
                } else {
                    logger.debug("Error when getting server status \(error)")
                }
            }
        }
    }

}

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
