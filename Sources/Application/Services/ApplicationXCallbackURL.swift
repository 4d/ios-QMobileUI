//
//  ApplicationXCallbackURL.swift
//  QMobileUI
//
//  Created by Eric Marchand on 12/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

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
    var dataSync: DataSync {
        return ApplicationDataSync.instance.dataSync
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) { // swiftlint:disable:this function_body_length
        guard let scheme = preferences.string(forKey: "com.4d.qa.urlScheme"),
            let urlSchemes = Manager.urlSchemes, urlSchemes.contains(scheme) else {
                return
        }
        Manager.shared.callbackURLScheme = scheme

        Manager.shared["sync"] = {  [weak self] parameters, success, failure, cancel in
            if let cancel = parameters["cancel"], cancel.boolValue {
                self?.dataSync.cancel()
            } else {
                /* let cancellable */ _ = self?.dataSync.sync { result in
                    switch result {
                    case .success:
                        var data: [String: String] = [:]
                        if let stampStorage = self?.dataSync.dataStore.metadata?.stampStorage {
                            data["globalStamp"] = String(stampStorage.globalStamp)
                            if let date = stampStorage.lastSync {
                                data["lastSync"] = DateFormatter.iso8601.string(from: date)
                            }
                        }
                        success(data)
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
        Manager.shared["reload"] = { [weak self] parameters, success, failure, cancel in
            if let cancel = parameters["cancel"], cancel.boolValue {
                self?.dataSync.cancel()
            } else {
                _ = self?.dataSync.sync(operation: .reload) { result in
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
        Manager.shared["dump"] = { parameters, success, failure, _ in
            let path: Path
            if let pathString = parameters["path"] {
                path = Path(pathString)
            } else {
                path = .userTemporary
            }
            _ =  ApplicationDataSync.instance.dataSync.dump(to: path) { result in
                switch result {
                case .success:
                    success(["path": path.rawValue])
                case .failure(let error):
                    failure(error)
                }
            }
        }

        Manager.shared["clear"] = { _, _, _, _ in
            // ApplicationDataSync.dataSync.dataStore.perform(DataStoreContextType)
        }

        Manager.shared["exit"] = { _, _, _, _ in
            exit(0)
        }
        Manager.shared["logger"] = { parameters, _, _, _ in
            if let levelString = parameters["setlevel"] {
                if let levelInt = Int(levelString), let level = Level(rawValue: levelInt) {
                    logger.outputLevel = level
                } else {
                    logger.warning("Unknown log level \(levelString)")
                }
            }
        }
        Manager.shared["settings"] = { parameters, _, _, _ in
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

// Mark Error
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
