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

/// Simple listener for data reload using closure.

/// Manager data reload action
class DataReloadManager {

    static let instance = DataReloadManager()

    //var listeners: [DataReloadListener] = []
    var cancellable = CancellableComposite()

   /* @objc func application(didEnterBackground notification: Notification) {
        cancel()
    }*/

   /* func listen(_ block: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> DataReloadListener {
        let listener = DataReloadListenerBlock(handler: block)
        self.listeners.append(listener)
        return listener
    }*/

   /* func remove(listener: DataReloadListener?) {
       // TODO implement remove listerer on data reload end
    }*/

   /* func cancel() {
        cancellable.cancel()
    }*/

    fileprivate func log(_ result: DataSync.SyncResult) {
        // Just log
        switch result {
        case .success:
            logger.info("data reloaded")
        case .failure(let error):
            logger.error("data reloading failed \(error)")
        }
    }

  /*  fileprivate func notify(_ result: DataSync.SyncResult) {
        for listener in self.listeners {
            listener.dataReloaded(result: result)
        }
    }*/

    func reload(delay: TimeInterval = 3, _ completionHandler: DataSync.SyncCompletionHandler? = nil) -> Cancellable {
        cancellable.cancel()
        cancellable = CancellableComposite()

        let center = NotificationCenter.default
        background(delay) { [weak self] in
            guard let this = self else {return}

            //center.addObserver(this, selector: #selector(this.application(didEnterBackground:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

            let reload = dataReload { [weak self] result in
                guard let this = self else {return}

                center.removeObserver(this)

                this.log(result)
                //this.notify(result)
                completionHandler?(result)
            }
            if let reload = reload {
                this.cancellable.append(reload)
            }
        }
        return cancellable
    }
}
