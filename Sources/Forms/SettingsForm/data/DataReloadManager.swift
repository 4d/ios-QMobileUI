//
//  DataReloadManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

import Moya

import QMobileAPI
import QMobileDataSync

/// Listen to data reload result
protocol DataReloadListener: NSObjectProtocol {
    func dataReloaded(result: QMobileDataSync.DataSync.SyncResult)
}

/// Simple listener for data reload using closure.
class DataReloadListenerBlock: NSObject, DataReloadListener {
    var handler: QMobileDataSync.DataSync.SyncCompletionHandler
    init(handler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) {
        self.handler = handler
    }
    func dataReloaded(result: QMobileDataSync.DataSync.SyncResult) {
        handler(result)
    }
}

/// Manager data reload action
class DataReloadManager {

    static let instance = DataReloadManager()

    var listeners: [DataReloadListener] = []
    var cancellable = CancellableComposite()

    @objc func application(didEnterBackground notification: Notification) {
        cancel()
    }

    func listen(_ block: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> DataReloadListener {
        let listener = DataReloadListenerBlock(handler: block)
        self.listeners.append(listener)
        return listener
    }

    func cancel() {
        cancellable.cancel()
    }

    func reload(_ completionHandler: DataSync.SyncCompletionHandler? = nil) {
        cancellable.cancel()
        cancellable = CancellableComposite()

        background(3) { [weak self] in
            guard let this = self, !this.cancellable.isCancelledUnlocked else {
                return
            }

            let center = NotificationCenter.default
            center.addObserver(this, selector: #selector(this.application(didEnterBackground:)), name: .UIApplicationDidEnterBackground, object: nil)

            let reload = dataReload { [weak self] result in
                if let this = self {
                    center.removeObserver(this)
                }

                // Just log
                switch result {
                case .success:
                    logger.info("data reloaded")
                case .failure(let error):
                    logger.error("data reloading failed \(error)")
                }

                for listener in this.listeners {
                    listener.dataReloaded(result: result)
                }
                completionHandler?(result)
            }
            if let reload = reload {
                self?.cancellable.append(reload)
            }
        }
    }
}
