//
//  ApplicationLoadDataStore.swift
//  Invoices
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

import Moya // Cancellable

/// Load the mobile database
class ApplicationLoadDataStore: NSObject {

    let dataSync: DataSync = DataSync.instance
}

extension ApplicationLoadDataStore: ApplicationService {

    static var instance: ApplicationService = ApplicationLoadDataStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {

        if let mustDrop = Preferences["dataStore.drop.atStart"] as? Bool, mustDrop {
            // drop data when application will terminate
            // TODO fix drop if not already loaded...
            drop { [weak self] in
                self?.load()
            }

        } else {
            logger.debug("Mobile database will be loaded")
            drop { [weak self] in
                self?.load()
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.debug("Mobile database will be saved")

        // XXX wait?

        if let mustDrop = Preferences["dataStore.drop.atEnd"] as? Bool, mustDrop {
            // drop data when application will terminate
            drop()

        } else {
            save()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.debug("Mobile database will be saved")
        save()
        // XXX wait?
    }

}
extension ApplicationLoadDataStore {

    func load() {
        dataStore.load { [unowned self] result in
            switch result {
            case .failure(let error):
                alert(title: "Failed to load the tables data from mobile database", error: error)
            case .success:
                logger.info("Mobile database has been loaded")
                // Import static data TODO must be done using task ordonanceur or listeners
                self.importData()
            }
        }
    }

    func save() {
        dataStore.save { result in
            switch result {
            case .failure(let error):
                logger.warning("Failed to save the tables data into mobile database: \(error)")
                alert(title: "Failed to save the tables data into mobile database", error: error)
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

    /// Temorary load data from files
    func importData() -> Cancellable {
        return dataSync.loadTable { _ in
            // TODO no need to sync if failed to load table structures??
            _ = self.dataSync.sync { _ in

            }
        }
    }

}

public func dataSync() {
     _ = (ApplicationLoadDataStore.instance as! ApplicationLoadDataStore).dataSync.sync { _ in
    }
}
