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
    fileprivate let operationQueue = OperationQueue(underlyingQueue: .background)
    fileprivate var dataStoreListeners: [NSObjectProtocol] = []
    fileprivate var apiManagerListeners: [NSObjectProtocol] = []

    /// To prevent doing two times, keep info about sync at start
    fileprivate var syncAtStartDone: Bool = false
    /// keep terminate information
    fileprivate var applicationWillTerminate: Bool = false

}

extension ApplicationDataSync: ApplicationService {

    public static var instance: ApplicationService {
        return _instance
    }

    static let _instance = ApplicationDataSync() // swiftlint:disable:this identifier_name

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        dataSync.delegate = self

        // Start sync after data store loading
        dataStoreListeners += [dataSync.dataStore.onLoad(queue: operationQueue) { [weak self] _ in
            self?.startSyncAtStart()
            }]
        if dataSync.dataStore.isLoaded {
            startSyncAtStart()
            assertionFailure("must not be loaded")
        }

        if Prephirences.Auth.reloadData {
            // When logout, drop the data...
            apiManagerListeners += [dataSync.apiManager.observe(APIManager.logout) { _ in
                _ = self.dataSync.drop()
                }]
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        startSyncIfEnterForeground()
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        if Prephirences.DataSync.Cancel.ifEnterBackground {
            dataSync.cancel()
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        applicationWillTerminate = true
        if Prephirences.DataSync.Cancel.atTheEnd {
            dataSync.cancel()
        }
        unobserve()
    }

}

extension ApplicationDataSync {

    fileprivate func unobserve() {
        dataSync.delegate = nil
        dataSync.dataStore.unobserve(dataStoreListeners)
        dataStoreListeners = []
        dataSync.apiManager.unobserve(apiManagerListeners)
        apiManagerListeners = []
    }

    fileprivate func startSyncIfEnterForeground() {
        // XXX factorize, by creating sequence of future according to work to do... (sync must be init after drop)
        let dataSync = self.dataSync
        if Prephirences.Reset.appData {
            Prephirences.Reset.appData = false // consumed
            ApplicationPreferences.resetSettings()
            let future: DataSync.SyncFuture = dataSync.drop()

            if Prephirences.DataSync.Sync.ifEnterForeground {
                future.onSuccess { _ in
                    logger.info("Data resetted after  entering in foreground")
                    let future = dataSync.sync()
                    future.onSuccess { _ in
                        logger.info("Data synchronized after resetting and entering in foreground")
                    }
                    future.onFailure { error in
                        logger.warning("Failed to synchronize data after resetting and entering in foreground - \(error)")
                    }
                }
                future.onFailure { error in
                    logger.warning("Failed to synchronize data after resetting and entering in foreground - \(error)")
                }
            } else {
                future.onSuccess { _ in
                    logger.info("Data resetted after entering in foreground")
                }
                future.onFailure { error in
                    logger.warning("Failed to reset data after entering in foreground - \(error)")
                }
            }
        } else {
            if Prephirences.DataSync.Sync.ifEnterForeground {
                let future: DataSync.SyncFuture = dataSync.sync()
                future.onSuccess {
                    logger.info("Data synchronized after entering in foreground")
                }
                future.onFailure { error in
                    logger.warning("Failed to synchronize data after entering in foreground - \(error)")
                }

            }
        }
    }

    func startSyncAtStart() {
        // TODO  #105180, if not loggued do nothing?
        guard !syncAtStartDone else { return }
        syncAtStartDone = true // do only one time

        let dataSync = self.dataSync

        if Prephirences.Reset.appData {
            Prephirences.Reset.appData = false // consumed
            ApplicationPreferences.resetSettings()

            let future: DataSync.SyncFuture = dataSync.drop()
            future.onSuccess {
                logger.info("Data initiliazed and resetted after launching the app")

                if Prephirences.DataSync.Sync.atStart {
                    let future: DataSync.SyncFuture = dataSync.sync()
                    future.onSuccess {
                        logger.info("Data synchronized after launching the app and resetting")
                    }
                    future.onFailure { error in
                        logger.warning("Failed to synchronized data after launching the app and resetting: \(error)")
                    }
                }
            }
            future.onFailure { error in
                logger.warning("Failed to reset data after launching the app \(error)")
                // XXX recreate the db?
            }
        } else {
            if Prephirences.DataSync.Sync.atStart {
                let future: DataSync.SyncFuture = dataSync.sync()
                future.onSuccess {
                    logger.info("Data synchronized after launching the app")
                }
                future.onFailure { error in
                    logger.warning("Failed to synchronized data after launching the app: \(error)")
                }
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

        // CLEAN: crappy way to update view of displayed details form. To do better, detail form must listen to its records change.
        onForeground {
            if let detailForm = UIApplication.detailViewController {
                if let formRecord = detailForm.record as? RecordBase {
                    if let bindedRecord = detailForm.view?.bindTo.record as? Record {
                        if formRecord != bindedRecord.store {
                            detailForm.dismiss(animated: true) {
                                logger.info("Close form with record deleted")
                            }
                        }
                    } else {
                       detailForm.view?.bindTo.record = formRecord
                    }
                } else {
                    // dismiss no more record in table
                    detailForm.dismiss(animated: true) {
                        logger.info("Close form with no more records in table")
                    }
                }
            }
        }
    }

    public func didDataSyncFailed(error: DataSyncError, operation: DataSync.Operation) {
        SwiftMessages.debug("Data \(operation) did end.\n \(error)")
    }

}

extension UIApplication {

    static var detailViewController: (DetailsForm & UIViewController)? {
        guard let topViewController = UIApplication.topViewController else { return nil }
        if let detailViewController = topViewController as? (DetailsForm & UIViewController) {
            return detailViewController
        }
        if let detailViewController = topViewController.parent as? (DetailsForm & UIViewController) {
            return detailViewController
        }
        if let navigationController = topViewController.parent as? UINavigationController {
            if let detailViewController = navigationController.topViewController as? (DetailsForm & UIViewController) {
                return detailViewController
            }
            if let detailViewController = navigationController.children.first as? (DetailsForm & UIViewController) {
                return detailViewController
            }
        }
        return nil
    }
}

// MARK: - Preferences

extension Prephirences {

    /// DataSync preferences.
    public struct DataSync: Prephirencable {

        public struct Cancel: Prephirencable { // swiftlint:disable:this nesting
            static let parent = DataSync.instance

            public static let atTheEnd: Bool = instance["atEnd"] as? Bool ?? true
            public static let ifEnterBackground: Bool = instance["ifEnterBackground"] as? Bool ?? false
        }

        public struct Sync: Prephirencable { // swiftlint:disable:this nesting
            static let parent = DataSync.instance

            public static let atStart: Bool = instance["atStart"] as? Bool ?? true
            public static let ifEnterForeground: Bool = instance["ifEnterForeground"] as? Bool ?? true
        }

    }

    public struct Reset { // swiftlint:disable:this nesting
        static var instance: MutablePreferencesType? { return Prephirences.sharedMutableInstance }

        public static var appData: Bool { // dynamic value, could be changed from setting, do not setore it
            get {
                return instance?["kFactoryReset"] as? Bool ?? false
            }
            set {
                instance?.set(newValue, forKey: "kFactoryReset")
            }
        }
    }
}
