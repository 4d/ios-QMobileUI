//
//  ApplicationDataStore.swift
//  Invoices
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileAPI
import QMobileDataStore
import QMobileDataSync
import Prephirences

import Moya // Cancellable

/// Load the mobile database
class ApplicationDataStore: NSObject {
    var listeners: [NSObjectProtocol] = []
}

extension ApplicationDataStore: ApplicationService {

    public static var instance: ApplicationService = ApplicationDataStore()
    public var servicePreferences: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "dataStore.")
    }

    var dataStore: DataStore {
        return DataStoreFactory.dataStore  // must use same in dataSync
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        var dataStore = self.dataStore
        dataStore.delegate = self

        if let mustDrop = servicePreferences["drop.atStart"] as? Bool, mustDrop {
            // drop before loadingb
            drop { [weak self] in
                self?.load()
            }

        } else {
            self.load()
        }

        registerEvent(dataStore)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.debug("Mobile database will be saved")

        // XXX wait?

        if let mustDrop = servicePreferences["drop.atEnd"] as? Bool, mustDrop {
            // drop data when application will terminate
            drop()
        } else {
            save()
        }
        var dataStore = self.dataStore
        dataStore.delegate =  nil
        unregisterEvent(dataStore)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.debug("Mobile database will be saved")
        save()
        // XXX wait?
    }

}
extension ApplicationDataStore {

    func load() {
        dataStore.load { result in
            switch result {
            case .failure(let error):
                alert(title: "Failed to load the data stored on phone", error: error)
            case .success:
                logger.info("Mobile database has been loaded")
            }
        }
    }

    func save() {
        dataStore.save { result in
            switch result {
            case .failure(let error):
                logger.warning("Failed to save the tables data into mobile database: \(error)")
                alert(title: "Failed to store data on phone", error: error)
            case .success:
                logger.info("Mobile database has been saved")
            }
        }
    }

    func drop(handler: (() -> Void)? = nil) {
        dataStore.drop { result in
            switch result {
            case .failure(let error):
                logger.warning("Failed to drop the mobile database tables data : \(error)")
            case .success:
                logger.info("Mobile database has been dropped")
            }
            handler?()
        }
    }

    fileprivate func registerEvent(_ dataStore: DataStore) {
        // Register to some event to log (XXX could be done by delegate some remove it and move the code)
        //listeners += [ds.onDrop(queue: operationQueue) { _ in }]
        //listeners += [ds.onSave(queue: operationQueue) { _ in }]
        let logDataStore: (Notification) -> Void = { notification in
            logger.debug("\(notification)")
        }
        listeners += [dataStore.observe(.dataStoreWillMerge, using: logDataStore)]
        listeners += [dataStore.observe(.dataStoreDidMerge, using: logDataStore)]
        listeners += [dataStore.observe(.dataStoreWillPerformAction, using: logDataStore)]
        listeners += [dataStore.observe(.dataStoreDidPerformAction, using: logDataStore)]
    }

    fileprivate func unregisterEvent(_ dataStore: DataStore) {
        for listener in listeners {
            dataStore.unobserve(listener)
        }
        listeners = []
    }

}

extension ApplicationDataStore: DataStoreDelegate {

    func dataStoreWillSave(_ dataStore: DataStore, context: DataStoreContext) {
    }

    func dataStoreDidSave(_ dataStore: DataStore, context: DataStoreContext) {
    }

    func objectsDidChange(dataStore: DataStore, context: DataStoreContext) {
    }

    func dataStoreWillMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext) {
    }

    func dataStoreDidMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext) {
    }

    public func dataStoreWillLoad(_ dataStore: DataStore) {
    }

    public func dataStoreDidLoad(_ dataStore: DataStore) {
    }

    public func dataStoreAlreadyLoaded(_ dataStore: DataStore) {
    }
}
