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

    // shared instance of data sync object for all QMoble application
    let dataSync: DataSync = DataSync.instance
}

extension ApplicationLoadDataStore: ApplicationService {

    static var instance: ApplicationService = ApplicationLoadDataStore()

    static var castedInstance: ApplicationLoadDataStore {
         // swiftlint:disable:next force_cast
        return instance as! ApplicationLoadDataStore
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {

        if let mustDrop = Preferences["dataStore.drop.atStart"] as? Bool, mustDrop {

            // drop before loading
            drop { [weak self] in
                self?.load {
                    
                }
            }

        } else {
            self.load()
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
                 _ = self.dataSync.sync { _ in

                }
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

}

public func dataSync(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHander) -> Cancellable? {
     return ApplicationLoadDataStore.castedInstance.dataSync.sync(completionHandler)
}
