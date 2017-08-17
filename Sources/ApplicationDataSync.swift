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

    let operationQueue = OperationQueue(underlyingQueue: DispatchQueue.background)
    var listeners: [NSObjectProtocol] = []
    var syncAtStartDone: Bool = false
    var applicationWillTerminate: Bool = false
}

extension ApplicationDataSync: ApplicationService {

    public static var instance: ApplicationService = ApplicationDataSync()

    public var servicePreferences: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "dataSync.")
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        let dataSync = ApplicationDataSync.dataSync
        dataSync.delegate = self
        
        let ds = dataSync.dataStore
        
        listeners += [ds.onLoad(queue: operationQueue) { [weak self] _ in
            if !(self?.syncAtStartDone ?? true) {
                self?.syncAtStart()
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

            let ds = dataSync.dataStore
            ds.unobserve(listener)
        }
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        let dataSync = ApplicationDataSync.dataSync
        dataSync.cancel()
        let cancel = servicePreferences["cancel.ifEnterForeground"] as? Bool ?? true
        if cancel {
            ApplicationDataSync.dataSync.cancel()
        }
    }
    
    func syncAtStart() {
        syncAtStartDone = true
        let sync = self.servicePreferences["sync.atStart"] as? Bool ?? true
        if sync {
            let dataSync = ApplicationDataSync.dataSync
            _ = dataSync.sync { _ in
                
            }
        }
    }

}

public func dataSync(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHander) -> Cancellable? {
    return ApplicationDataSync.dataSync.sync(completionHandler)
}

public func dataLastSync() -> Date? {
    return nil // ApplicationDataSync.dataSync.dataStore?.
}

extension ApplicationDataSync: DataSyncDelegate {
    public func willDataSyncBegin(tables: [QMobileAPI.Table]) -> Bool {
        if applicationWillTerminate /* stop sync is app shutdown */ {
            return true
        }
        // XXX could ask user here
        return false
    }

    public func willDataSyncBegin(for table: QMobileAPI.Table) {

    }

    public func dataSync(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo) {

    }

    public func didDataSyncEnd(for table: QMobileAPI.Table, page: QMobileAPI.PageInfo) {

    }

    public func didDataSyncFailed(for table: QMobileAPI.Table, error: Swift.Error) {

    }

    public func didDataSyncEnd(tables: [QMobileAPI.Table]) {
        let messageView = MessageView.viewFromNib(layout: .CardView)
        messageView.configureTheme(.success)
        messageView.configureDropShadow()
        messageView.configureContent(body: "Data updated")
        messageView.button?.isHidden = true
        var successConfig = SwiftMessages.defaultConfig
        successConfig.preferredStatusBarStyle = .lightContent
        successConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        messageView.titleLabel?.isHidden = true
        
        SwiftMessages.show(config: successConfig, view: messageView)
    }

    public func didDataSyncFailed(error: Swift.Error) {
        let messageView = MessageView.viewFromNib(layout: .TabView)
        messageView.button?.setTitle("Ok", for: .normal)
        messageView.configureTheme(.error)
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindowLevelNormal)

        if let error = error as? LocalizedError {
            messageView.configureContent(title: error.errorDescription ?? "An error occurs", body: error.failureReason ?? "")
        }

        messageView.bodyLabel?.isHidden = (messageView.bodyLabel?.text ?? "").isEmpty
        
        SwiftMessages.show(config: config, view: messageView)
    }

}
