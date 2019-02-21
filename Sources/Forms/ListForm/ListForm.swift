//
//  ListForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import Result
import SwiftMessages
import Prephirences
import Moya

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

public protocol ListForm: DataSourceDelegate, DataSourceSortable, Form {

    var tableName: String { get }
    var dataSource: DataSource! { get }
}

let searchController = UISearchController(searchResultsController: nil)
extension ListForm {

    func configureListFormView(_ view: UIView, _ record: AnyObject, _ indexPath: IndexPath) {
        // Give view information about records, let binding fill the UI components
        let entry = self.dataSource.entry
        entry.indexPath = indexPath
        view.table = entry
        // view.record = record
    }

    var defaultTableName: String {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)

        let name = className.camelFirst
        if NSClassFromString(name) != nil { // check entity
            return name
        }
        logger.error("Looking for class \(className) to determine the type of records to load. But no class with this name found in the project. Check your data model.")
        abstractMethod(className: className)
    }

    public var firstRecord: Record? {
        return dataSource.record(at: IndexPath.firstRow)
    }

    public var lastRecord: Record? {
        guard let index = dataSource.lastIndexPath else {
            return nil
        }
        return dataSource.record(at: index)
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
                                        configure: self.configurelogout(sender, source))

                } else {
                    let api = APIManager.instance
                    _ = api.logout { _ in
                        _ = APIManager.instance.authentificate(login: "") { authResult in
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
    /// Could be overriden to display or not the result..
    func refreshMessage(_ result: DataSync.SyncResult) {
        switch result {
        case .success:
            SwiftMessages.info("Data has been reloaded")
        case .failure(let error):
            if case .apiError(let apiError) = error, let statusText = apiError.restErrors?.statusText {
                SwiftMessages.error(title: error.errorDescription ?? "Issue when reloading data", message: statusText)
            } else {
                SwiftMessages.error(title: error.errorDescription ?? "Issue when reloading data", message: error.failureReason ?? "")
            }
        }
    }

    // Configure logout dialog and action
    func configurelogout(_ sender: Any? = nil, _ source: UIViewController) -> ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config) {
        return { (messageView, config) in
            messageView.tapHandler = { _ in
                SwiftMessages.hide()
                self.logout(sender, source)
            }
            var config = config
            config.presentationStyle = .center
            config.duration = .forever
            // no interactive because there is no way yet to get background tap handler to make logout
            config.dimMode = .gray(interactive: false)
            return config
        }
    }

    func logout(_ sender: Any? = nil, _ source: UIViewController) {
        foreground {
            /// XXX check that there is no issue with that, view controller cycle for instance
            if let destination = Main.instantiate() {
                let identifier = "logout"
                // prepare destination like done with segue
                source.prepare(for: UIStoryboardSegue(identifier: identifier, source: source, destination: destination), sender: sender)
                // and present it
                source.present(destination, animated: true) {
                    logger.debug("\(destination) presented by \(source)")
                }
            }
        }
    }

}
