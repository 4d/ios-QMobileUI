//
//  ApplicationXCallbackURL.swift
//  QMobileUI
//
//  Created by Eric Marchand on 12/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CallbackURLKit
import XCGLogger
import FileKit

import QMobileDataSync
import QMobileAPI
import QMobileDataStore

class ApplicationXCallbackURL: NSObject {
}

extension ApplicationXCallbackURL: ApplicationService {

    static var instance: ApplicationService = ApplicationXCallbackURL()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let scheme = preferences.string(forKey: "com.4d.qa.urlScheme"),
            let urlSchemes = Manager.urlSchemes, urlSchemes.contains(scheme) else {
                return
        }
        Manager.shared.callbackURLScheme = scheme

        Manager.shared["sync"] = { parameters, success, failure, cancel in
            if let cancel = parameters["cancel"], cancel.boolValue {
                ApplicationDataSync.dataSync.cancel()
            } else {
                /* let cancellable */ _ = dataSync { result in
                    switch result {
                    case .success:
                        success(nil)
                    case .failure(let error):
                        if case .cancel = error {
                            cancel()
                        } else {
                            failure(error)
                        }
                    }
                }
            }
        }
        Manager.shared["reload"] = { parameters, success, failure, cancel in
            if let cancel = parameters["cancel"], cancel.boolValue {
                ApplicationDataSync.dataSync.cancel()
            } else {
                _ = dataSync(operation: .reload) { result in
                    switch result {
                    case .success:
                        success(nil)
                    case .failure(let error):
                        if case .cancel = error {
                            cancel()
                        } else {
                            failure(error)
                        }
                    }
                }
            }
        }
        Manager.shared["dump"] = { parameters, success, failure, cancel in
            let path: Path
            if let pathString = parameters["path"] {
                path = Path(pathString)
            } else {
                path = .userTemporary
            }
            _ =  ApplicationDataSync.dataSync.dump(to: path) {

                success(nil)
            }
        }

        Manager.shared["clear"] = { parameters, success, failure, cancel in
            // ApplicationDataSync.dataSync.dataStore.perform(DataStoreContextType)
        }

        Manager.shared["exit"] = { parameters, success, failure, cancel in
            exit(0)
        }
        Manager.shared["logger"] = { parameters, success, failure, cancel in
            if let levelString = parameters["setlevel"] {
                if let levelInt = Int(levelString), let level = Level(rawValue: levelInt) {
                    logger.outputLevel = level
                } else {
                    logger.warning("Unknown log level \(levelString)")
                }
            }
        }
        Manager.shared["settings"] = { parameters, success, failure, cancel in
            if let levelString = parameters["setlevel"] {
                if let levelInt = Int(levelString), let level = Level(rawValue: levelInt) {
                    logger.outputLevel = level
                } else {
                    logger.warning("Unknown log level \(levelString)")
                }
            }
        }
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        if  Manager.shared.handleOpen(url: url) {
            logger.debug("Callback url action receive: \(url)")
        }
    }

}

extension DataSyncError: FailureCallbackError {
    public var code: Int {
        switch self {
        case .retain:
            return 1
        case .delegateRequestStop:
            return 2
        case .dataStoreNotReady:
            return 3
        case .dataStoreError:
            return 4
        case .apiError:
            return 5
        case .noTables:
            return 6
        case .missingRemoteTables:
            return 7
        case .missingRemoteTableAttributes:
            return 8
        case .cancel:
            return 9
        case .dataCache:
            return 10
        case .underlying:
            return 11
        }
    }
    public var message: String {
        return self.errorDescription ?? ""
    }
}
