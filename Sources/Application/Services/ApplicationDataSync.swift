//
//  ApplicationDataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 17/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import UIKit

import QMobileAPI
import QMobileDataStore
import QMobileDataSync
import Prephirences
import SwiftMessages

import Moya // Cancellable

/// Load the mobile database
class ApplicationDataSync: NSObject {

    // shared instance of data sync object for all QMoble application
    static let dataSync: DataSync = DataSync.instance

    let operationQueue = OperationQueue(underlyingQueue: .background)
    var listeners: [NSObjectProtocol] = []
    var syncAtStartDone: Bool = false
    var applicationWillTerminate: Bool = false
}

extension ApplicationDataSync: ApplicationService {

    public static var instance: ApplicationService = ApplicationDataSync()

    public var servicePreferences: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "dataSync.")
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let dataSync = ApplicationDataSync.dataSync
        dataSync.delegate = self

        // swiftlint:disable:next identifier_name
        let ds = dataSync.dataStore

        listeners += [ds.onLoad(queue: operationQueue) { [weak self] _ in
            guard let this = self else {
                return
            }
            if !this.syncAtStartDone {
                this.syncAtStart()
            }
            }]
        if ds.isLoaded {
            syncAtStart() // XXX could have bug if loaded just before registering
        }
        //listeners += [ds.onDrop(queue: operationQueue) { _ in }]
        //listeners += [ds.onSave(queue: operationQueue) { _ in }]

        listeners += [ds.observe(.dataStoreWillMerge) { notification in
            logger.debug("\(notification)")
        }]
        listeners += [ds.observe(.dataStoreDidMerge) { notification in
            logger.debug("\(notification)")
        }]
        listeners += [ds.observe(.dataStoreWillPerformAction) { notification in
            logger.debug("\(notification)")
        }]
        listeners += [ds.observe(.dataStoreDidPerformAction) { notification in
            logger.debug("\(notification)")
        }]
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        applicationWillTerminate = true
        let cancel = servicePreferences["cancel.atEnd"] as? Bool ?? true
        if cancel {
            ApplicationDataSync.dataSync.cancel()
        }
        for listener in listeners {
            let dataSync = ApplicationDataSync.dataSync
            dataSync.delegate = nil

            let dataStore = dataSync.dataStore
            dataStore.unobserve(listener)
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        let cancel = servicePreferences["cancel.ifEnterForeground"] as? Bool ?? false
        if cancel {
            ApplicationDataSync.dataSync.cancel()
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        let cancel = servicePreferences["cancel.ifEnterBackground"] as? Bool ?? true
        if cancel {
            ApplicationDataSync.dataSync.cancel()
        }
    }

    func syncAtStart() {
        syncAtStartDone = true
        let sync = self.servicePreferences["sync.atStart"] as? Bool ?? false
        let dataSync = ApplicationDataSync.dataSync

        let future: DataSync.SyncFuture = sync ? dataSync.sync(): dataSync.initFuture()
        future.onSuccess {
            logger.debug("data from data store initilized")
            if sync {
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
public func dataLastSync() -> Date? {
    let dataStore = ApplicationDataSync.dataSync.dataStore
    var metadata = dataStore.metadata
    return metadata?.lastSync
}

// MARK: DataSyncDelegate
extension ApplicationDataSync: DataSyncDelegate {
    public func willDataSyncBegin(tables: [QMobileAPI.Table]) -> Bool {
        if applicationWillTerminate /* stop sync is app shutdown */ {
            return true
        }
        // XXX could ask user here
        return false
    }

    public func willDataSyncBegin(for table: QMobileAPI.Table) {}

    public func dataSync(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo) {}

    public func didDataSyncEnd(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo) {}

    public func didDataSyncFailed(for table: QMobileAPI.Table, error: DataSyncError) {}

    public func didDataSyncEnd(tables: [QMobileAPI.Table]) {}

    public func didDataSyncFailed(error: DataSyncError) {}

}
