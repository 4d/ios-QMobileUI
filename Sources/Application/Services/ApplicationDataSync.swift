//
//  ApplicationDataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 17/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences
import SwiftMessages
import Moya // Cancellable

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

/// Load the mobile database
class ApplicationDataSync: NSObject {

    // shared instance of data sync object for all QMoble application
    static let dataSync: DataSync = DataSync.instance

    let operationQueue = OperationQueue(underlyingQueue: .background)
    var dataStoreListeners: [NSObjectProtocol] = []
    var apiManagerListeners: [NSObjectProtocol] = []
    var syncAtStartDone: Bool = false
    var applicationWillTerminate: Bool = false
}

extension ApplicationDataSync: ApplicationService {

    public static var instance: ApplicationService = ApplicationDataSync()

    public var servicePreferences: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "dataSync.")
    }
    fileprivate var cancelAtTheEnd: Bool { return servicePreferences["cancel.atEnd"] as? Bool ?? true }
    fileprivate var cancelIfEnterForeground: Bool { return servicePreferences["cancel.ifEnterForeground"] as? Bool ?? false }
    fileprivate var cancelIfEnterBackground: Bool { return servicePreferences["cancel.ifEnterBackground"] as? Bool ?? true }
    fileprivate var syncAtStart: Bool { return servicePreferences["sync.atStart"] as? Bool ?? false }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let dataSync = ApplicationDataSync.dataSync
        dataSync.delegate = self

        let dataStore = dataSync.dataStore
        dataStoreListeners += [dataStore.onLoad(queue: operationQueue) { [weak self] _ in
            guard let this = self else { return }
            this.startSync()
            }]
        //dataStoreListeners += [ds.onSave(queue: operationQueue) { _ in }]
        //dataStoreListeners += [ds.onSave(queue: operationQueue) { _ in }]
        if dataSync.dataStore.isLoaded {
            startSync()
        }

        let apiManager = dataSync.apiManager
        if Prephirences.Auth.Logout.atStart {
            _ = apiManager.logout(token: Prephirences.Auth.Logout.token) { _ in
                Prephirences.Auth.Logout.token = nil
            }
        }

        // Register to some event to log
        if Prephirences.Auth.reloadData {
            apiManagerListeners += [apiManager.observe(.apiManagerLogout) { _ in
                _ = dataSync.drop()
                }]
        }

    }

    public func applicationWillTerminate(_ application: UIApplication) {
        applicationWillTerminate = true
        let cancel = cancelAtTheEnd
        let dataSync = ApplicationDataSync.dataSync
        if cancel {
            dataSync.cancel()
        }
        dataSync.delegate = nil

        let dataStore = dataSync.dataStore
        for listener in dataStoreListeners {
            dataStore.unobserve(listener)
        }
        dataStoreListeners = []
        let apiManager = dataSync.apiManager
        for listener in apiManagerListeners {
            apiManager.unobserve(listener)
        }
        apiManagerListeners = []
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        if cancelIfEnterForeground {
            ApplicationDataSync.dataSync.cancel()
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        if cancelIfEnterBackground {
            ApplicationDataSync.dataSync.cancel()
        }
    }

    func startSync() {
        guard !syncAtStartDone else { return }
        syncAtStartDone = true
        let dataSync = ApplicationDataSync.dataSync
        let syncAtStart = self.syncAtStart
        let future: DataSync.SyncFuture = syncAtStart ? dataSync.sync(): dataSync.initFuture()
        future.onSuccess {
            logger.debug("data from data store initiliazed")
            if syncAtStart {
                SwiftMessages.info("Data updated")
            }
        }
        future.onFailure { error in
            logger.warning("Failed to initialize data from data store \(error)")
        }
    }

}

public func dataSync(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return ApplicationDataSync.dataSync.sync(completionHandler)
}

public func dataReload(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return ApplicationDataSync.dataSync.reload(completionHandler)
}

/// Get the last data sync date.
public func dataLastSync() -> Foundation.Date? {
    let dataStore = ApplicationDataSync.dataSync.dataStore
    var metadata = dataStore.metadata
    return metadata?.lastSync
}

// MARK: DataSyncDelegate
extension ApplicationDataSync: DataSyncDelegate {

    func willDataSyncWillLoad(tables: [Table]) {
        SwiftMessages.debug("Data will be loaded from embedded data")
    }

    func willDataSyncDidLoad(tables: [Table]) {
        SwiftMessages.debug("Data has been loaded from embedded data")
    }

    public func willDataSyncWillBegin(tables: [QMobileAPI.Table], operation: DataSync.Operation, cancellable: Cancellable) {

        SwiftMessages.debug("Data \(operation) will begin")
    }
    public func willDataSyncDidBegin(tables: [QMobileAPI.Table], operation: DataSync.Operation) -> Bool {
        if applicationWillTerminate /* stop sync is app shutdown */ {
            return true
        }
        SwiftMessages.debug("Data \(operation) did begin")
        // XXX could ask user here
        return false
    }

    public func willDataSyncBegin(for table: QMobileAPI.Table, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) begin for \(table.name)")
    }

    public func dataSync(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) page \(page) for \(table.name)")
    }

    public func didDataSyncEnd(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) did end for \(table.name)")
    }

    public func didDataSyncFailed(for table: QMobileAPI.Table, error: DataSyncError, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) did end with for \(table.name).\n \(error)")
    }

    public func didDataSyncEnd(tables: [QMobileAPI.Table], operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) did end")
    }

    public func didDataSyncFailed(error: DataSyncError, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) did end.\n \(error)")
    }

}
