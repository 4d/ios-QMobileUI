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

    /// shared instance of data sync object for all QMoble application
    var dataSync: DataSync {
        return DataSync.instance // lazy loaded, to let qmobileURL be created from settings/preferences
    }
    let operationQueue = OperationQueue(underlyingQueue: .background)
    var dataStoreListeners: [NSObjectProtocol] = []
    var apiManagerListeners: [NSObjectProtocol] = []

    /// To prevent doing two times, keep info about sync at start
    var syncAtStartDone: Bool = false
    /// keep terminate information
    var applicationWillTerminate: Bool = false

}

extension ApplicationDataSync: ApplicationService {

    public static var instance: ApplicationService {
        return _instance
    }

    static let _instance = ApplicationDataSync() // swiftlint:disable:this identifier_name

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        dataSync.delegate = self

        // Start sync after data store loading
        let dataStore = dataSync.dataStore
        dataStoreListeners += [dataStore.onLoad(queue: operationQueue) { [weak self] _ in
            guard let this = self else { return }
            this.startSyncAtStart()
            }]
        if dataSync.dataStore.isLoaded {
            startSyncAtStart()
        }

        // Register to some event to log
        if Prephirences.Auth.reloadData {
             let apiManager = dataSync.apiManager
            apiManagerListeners += [apiManager.observe(.apiManagerLogout) { _ in
                _ = self.dataSync.drop()
                }]
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        applicationWillTerminate = true
        if Prephirences.DataSync.Cancel.atTheEnd {
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
        if Prephirences.DataSync.Sync.ifEnterForeground {
            // sync if enter foreground
            let future: DataSync.SyncFuture = dataSync.sync()
            future.onSuccess {
                logger.debug("data from data store synchronized")
                //SwiftMessages.info("Data updated")
            }
            future.onFailure { error in
                /// XXX if not logued do not warn?
                logger.warning("Failed to synchronize data - \(error)")
            }

        } else if Prephirences.DataSync.Cancel.ifEnterForeground {
            dataSync.cancel()
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        if Prephirences.DataSync.Cancel.ifEnterBackground {
           dataSync.cancel()
        }
    }

}

extension ApplicationDataSync {

    func startSyncAtStart() {
        // TODO  #105180, if not loggued do nothing?
        guard !syncAtStartDone else { return }
        syncAtStartDone = true // do only one time
        let syncAtStart = Prephirences.DataSync.Sync.atStart
        let future: DataSync.SyncFuture = syncAtStart ? dataSync.sync(): dataSync.initFuture()
        future.onSuccess {
            logger.debug("Data from data store initiliazed")
            if syncAtStart {
                //SwiftMessages.info("Data updated")
                logger.info("Data synchronized at start")
            }
        }
        future.onFailure { error in
            if syncAtStart {
                logger.warning("Failed to initialize data from data store or synchronize data: \(error)")
            } else {
                logger.warning("Failed to initialize data from data store \(error)")
            }
        }
    }

}

public func dataSync(operation: DataSync.Operation = .sync, _ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return ApplicationDataSync._instance.dataSync.sync(operation: operation, completionHandler)
}

/// Get the last data sync date.
public func dataLastSync() -> Foundation.Date? {
    return ApplicationDataSync._instance.dataSync.dataStore.metadata?.lastSync
}

// MARK: - DataSyncDelegate
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

// MARK: - Preferences

extension Prephirences {

    /// DataSync preferences.
    public struct DataSync: Prephirencable {

        public struct Cancel: Prephirencable { // swiftlint:disable:this nesting
            static let parent = DataSync.instance

            public static let atTheEnd: Bool = instance["atEnd"] as? Bool ?? false
            public static let ifEnterForeground: Bool = instance["ifEnterForeground"] as? Bool ?? true
            public static let ifEnterBackground: Bool = instance["ifEnterBackground"] as? Bool ?? false

        }

        public struct Sync: Prephirencable { // swiftlint:disable:this nesting
            static let parent = DataSync.instance

            public static let atStart: Bool = instance["atStart"] as? Bool ?? true
            public static let ifEnterForeground: Bool = instance["ifEnterForeground"] as? Bool ?? true

        }
    }

}
