//
//  ApplicationReachability.swift
//  QMobileUI
//
//  Created by Eric Marchand on 06/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import Combine
import UIKit

import Moya
import class Alamofire.NetworkReachabilityManager
import Prephirences

import QMobileAPI
import QMobileDataSync

/// Service to check network avaibility and also configured server.
class ApplicationReachability: NSObject {

    public static var instance: ApplicationReachability = ApplicationReachability()

    var reachabilityTask: Moya.Cancellable?
    var reachabilityStatus: NetworkReachabilityStatus = .unknown {
        didSet {
            notifyReachabilityChanged(status: reachabilityStatus, old: oldValue)
        }
    }
    var listeners: [ReachabilityListener] = []

    var apiManagerObserver: NSObjectProtocol?
    var serverInfoTask: Moya.Cancellable?
    var serverInfo: WebTestInfo?
    var serverStatusTask: Moya.Cancellable?
    var serverStatus: ServerStatus = .unknown {
        didSet {
            notifyStatusChanged(status: serverStatus, old: oldValue)
        }
    }
    var serverStatusListener: [ServerStatusListener] = []

    open func add(reachabilityListener listener: ReachabilityListener) {
        self.listeners.append(listener)
    }
    func notifyReachabilityChanged(status: NetworkReachabilityStatus, old: NetworkReachabilityStatus) {
        for listener in listeners {
            listener.onReachabilityChanged(status: status, old: old)
        }
    }
    open func add(serverStatusListener listener: ServerStatusListener) {
        self.serverStatusListener.append(listener)
    }
    func notifyStatusChanged(status: ServerStatus, old: ServerStatus) {
        for listener in serverStatusListener {
            listener.onServerStatusChanged(status: status, old: old)
        }
    }
    open func add(listener: ReachabilityListener & ServerStatusListener) {
        self.add(reachabilityListener: listener)
        self.add(serverStatusListener: listener)
    }
}

public protocol ReachabilityListener: NSObjectProtocol {
    func onReachabilityChanged(status: NetworkReachabilityStatus, old: NetworkReachabilityStatus)
}

public protocol ServerStatusListener: NSObjectProtocol {
    func onServerStatusChanged(status: ServerStatus, old: ServerStatus)
}

// MARK: service
extension ApplicationReachability: ApplicationService {

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
        return instance.reachabilityStatus.isReachable
    }

    fileprivate func startMonitoringReachability() {
        //self.reachability = APIManager.instance.reachability { status in
        self.reachabilityTask = APIManager.reachability { status in
            self.reachabilityStatus = status
            switch status {
            case .reachable(let type):
                logger.debug("Server is reachable using \(type)")
                self.refreshServerInfo(APIManager.instance)
            case .notReachable, .unknown:
                logger.debug("Server not reachable")
                self.serverStatus = .noNetwork
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
        let apiManager = APIManager.instance // some weird issue with parameter, use singleton
        self.serverInfoTask = apiManager.loadWebTestInfo(callbackQueue: .background) { [weak self] result in
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

        self.serverStatus = .checking
        self.serverStatusTask = apiManager.status { [weak self] result in
            self?.serverStatus = .done(result)
            switch result {
            case .success(let serverStatus):
                logger.info("ServerStatus \(serverStatus)")
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

open class ServerStatusManager {

    static let instance = ServerStatusManager()

    var listeners: [ServerStatusListener] = []
    var bag = Set<AnyCancellable>()

    /// Queue for checking
    public let queue: OperationQueue = {
        let operationQueue = OperationQueue()

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility

        return operationQueue
    }()

    public private(set) var serverStatus: ServerStatus = .unknown {
        didSet {
            notifyListener(value: serverStatus, old: oldValue)
        }
    }

    open func notifyListener(value serverStatus: ServerStatus, old: ServerStatus) {
        for listener in listeners {
            listener.onServerStatusChanged(status: serverStatus, old: old)
        }
    }

    open func add(listener: ServerStatusListener) {
        listener.onServerStatusChanged(status: serverStatus, old: .unknown)
        self.listeners.append(listener)
    }

    open func remove(listener: ServerStatusListener) {
        self.listeners.removeAll(where: { $0 === listener })
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
        self.bag.removeAll()
        // queue.waitUntilAllOperationsAreFinished() // bad, do not wait on main thread

        // Start checking in a new task

        let checkingUUID = UUID()
        /*self.queue.addOperation {
            //logger.verbose("Checking status \(checkingUUID). sleep start")
            //Thread.sleep(forTimeInterval: delay)
            //logger.verbose("Checking status \(checkingUUID). sleep end")
        }*/
        self.queue.addOperation {
            self.serverStatus(.checking)
            logger.debug("Checking server status \(url) \(checkingUUID) start")
            let apiManager = APIManager(url: url)

            let checkstatus = apiManager.status()
            checkstatus.onComplete { [weak self] result in
                self?.queue.addOperation {
                    self?.serverStatus(.done(result))
                    logger.debug("Checking status \(url) \(checkingUUID) end: \(result)")
                    APIManager.instance = apiManager
                    DataSync.instance.apiManager = apiManager
                }
            }
            .sink()
            .store(in: &self.bag)
        }
    }

    private func serverStatus(_ status: ServerStatus) {
        self.serverStatus = status
    }

}
