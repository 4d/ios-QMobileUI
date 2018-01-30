//
//  Operation.swift
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___
//  ___COPYRIGHT___

import Foundation
import QMobileDataSync
import QMobileUI
import Moya

public func dataSync(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return QMobileUI.dataSync(completionHandler)
}

public func dataReload(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return QMobileUI.dataReload(completionHandler)
}

public func dataLastSync() -> Date? {
    return QMobileUI.dataLastSync()
}
