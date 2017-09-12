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
import QMobileDataSync
import QMobileAPI
import QMobileDataStore

class ApplicationXCallbackURL: NSObject {
    let callbackManager = Manager(callbackURLScheme: preferences.string(forKey: "com.4d.qa.urlScheme"))
}

extension ApplicationXCallbackURL: ApplicationService {
    
    static var instance: ApplicationService = ApplicationXCallbackURL()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {

        if let urlSchemes = Manager.urlSchemes, urlSchemes.contains(callbackManager.callbackURLScheme ?? "") {

            callbackManager["sync"] = { parameters, success, failure, cancel in
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
            callbackManager["reload"] = { parameters, success, failure, cancel in
                if let cancel = parameters["cancel"], cancel.boolValue {
                    ApplicationDataSync.dataSync.cancel()
                } else {
                    _ = dataReload { result in
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
            callbackManager["exit"] = { parameters, success, failure, cancel in
                exit(0)
            }
            callbackManager["logger"] = { parameters, success, failure, cancel in
                if let levelString = parameters["setlevel"] {
                    if let levelInt = Int(levelString), let level = Level(rawValue: levelInt) {
                        logger.outputLevel = level
                    } else {
                        logger.warning("Unknown log level \(levelString)")
                    }
                }
            }
        }
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) {
        if callbackManager.handleOpen(url: url) {
            logger.debug("Callback url action receive: \(url)")
        }
    }
    
}

extension DataSyncError: FailureCallbackError {
    public var code: Int {
        return -1
    }
    public var message: String {
     return ""
    }
}
