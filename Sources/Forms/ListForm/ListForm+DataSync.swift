//
//  ListForm+DataSync.swift
//  QMobileUI
//
//  Created by Eric Marchand on 08/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import Moya
import Prephirences
import SwiftMessages

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

extension ListForm {

    /// Return information about current table using 4D table and field naming
    public var table: Table? {
        let dataSync = ApplicationDataSync._instance.dataSync
        assert(!dataSync.tablesInfoByTable.isEmpty) // not loaded...

        for (table, tableInfo) in dataSync.tablesInfoByTable where tableInfo.name == self.tableName {
            return table
        }
        return nil
    }

    /// Return information about current table using mobile database table and field naming
    public var tableInfo: DataStoreTableInfo? {
        let dataSync = ApplicationDataSync._instance.dataSync
        //assert(!dataSync.tablesInfoByTable.isEmpty) // not loaded...

        for (_, tableInfo) in dataSync.tablesInfoByTable where tableInfo.name == self.tableName {
            return tableInfo
        }
        return nil
    }

    // MARK: - data sync refresh

    /// Do the data sync, manage error to retry if necessary.
    func doRefresh(_ sender: Any? = nil, _ source: UIViewController, tryCount: Int = Prephirences.Auth.Login.Guest.maxRetry, _ complementionHandler: @escaping DataSync.SyncCompletionHandler) -> Cancellable? {
        let cancellable = CancellableComposite()
        let dataSyncTask = dataSync { result in
            let title = "Issue when reloading data"
            if case .failure(let dataSyncError) = result, dataSyncError.mustRetry {
                if Prephirences.Auth.Login.form {
                    // Display error before logout
                    SwiftMessages.error(title: dataSyncError.errorDescription ?? title,
                                        message: dataSyncError.mustRetryMessage,
                                        configure: self.configureLogoutMessage(sender, source))

                } else {
                    ApplicationAuthenticate.retryGuestLogin { authResult in
                        switch authResult {
                        case .success:
                            // retry XXX manage it elsewhere with a request retrier
                            if tryCount > 0 {
                                if let dataSyncTask = self.doRefresh(sender, source, tryCount: tryCount - 1, complementionHandler) {
                                    cancellable.append(dataSyncTask)
                                }
                            } else {
                                complementionHandler(result)
                            }
                        case .failure(let authError):
                            if authError.restErrors?.statusText != nil { // If a failure message is in guest login, it will be more useful than first error
                                complementionHandler(.failure(.apiError(authError)))
                            } else {
                                complementionHandler(result)
                            }
                        }
                    }
                }
            } else {
                complementionHandler(result)
            }
        }
        if let dataSyncTask = dataSyncTask {
            cancellable.append(dataSyncTask)
            return cancellable
        }
        return nil
    }

    /// Display a message when data refresh end.
    /// Could be overriden(not called) to display or not the result..
    func refreshMessage(_ result: DataSync.SyncResult) {
        switch result {
        case .success:
            SwiftMessages.info("Data has been reloaded", configure: { _, config in
                var config = config
                // More view controller do not support presentationContext = .automatic, so change it here
                if let viewController = self as? UIViewController {
                    if let moreNavigationController = viewController.parent as? UINavigationController,
                        moreNavigationController.isMoreNavigationController {
                        config.presentationContext = .viewController(viewController)
                    } else if viewController.navigationItem.searchController != nil { // or check searchableAsTitle?
                        config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
                    }
                }
                return config
            })
        case .failure(let error):
            let title = "Issue when reloading data"

            if case .apiError(let apiError) = error {
                if let statusText = apiError.restErrors?.statusText { // dev message
                    SwiftMessages.error(title: error.errorDescription ?? title, message: statusText)
                    return
                } else /*if apiError.isRequestCase(.connectionLost) ||  apiError.isRequestCase(.notConnectedToInternet) {*/ // not working always
                    if !ApplicationReachability.isReachable { // so check reachability status
                        SwiftMessages.error(title: "", message: "Please check your network settings and data cover...")
                        return
                }
                /*}*/
                if let afError = apiError.afError {
                    if case .sessionTaskFailed(let urlError)  = afError {
                        SwiftMessages.warning(urlError.localizedDescription)
                        return
                    }
                }
            }
            /// Localized error
            if let failureReason = error.failureReason {
                SwiftMessages.warning(failureReason)
            } else if let recoverySuggestion = error.recoverySuggestion {
                SwiftMessages.warning(error.errorDescription ?? title) { view, config in
                    view.configureContent(title: title, body: recoverySuggestion)
                    return config
                }
            } else {
                SwiftMessages.error(title: error.errorDescription ?? title, message: "")
            }
        }
    }

    // Configure logout dialog and action
    fileprivate func configureLogoutMessage(_ sender: Any? = nil, _ source: UIViewController) -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = { _ in
                SwiftMessages.hide()
                (ApplicationAuthenticate.instance as? ApplicationAuthenticate)?.logoutUI(sender, source)
            }
            var config = config
            config.presentationStyle = .center
            config.duration = .forever
            // no interactive because there is no way yet to get background tap handler to make logout
            config.dimMode = .gray(interactive: false)
            return config
        }
    }

}
