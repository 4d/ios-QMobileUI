//
//  ApplicationReachability.swift
//  QMobileUI
//
//  Created by Eric Marchand on 06/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Moya
import class Alamofire.NetworkReachabilityManager

import QMobileAPI

class ApplicationReachability: NSObject {
    var reachabilityTask: Cancellable?
    var reachabilityStatus: NetworkReachabilityStatus = .unknown
}

extension ApplicationReachability: ApplicationService {

    public static var instance: ApplicationService {
        return _instance
    }

    static let _instance = ApplicationReachability() // swiftlint:disable:this identifier_name

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        monitorReachability(start: true)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        monitorReachability(start: false)
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
    }

}

extension ApplicationReachability {

    static var isReachable: Bool {
        return _instance.reachabilityStatus.isReachable
    }

    fileprivate func monitorReachability(start: Bool) {
        if start {
            //self.reachability = APIManager.instance.reachability { status in
            self.reachabilityTask = APIManager.reachability { status in
                self.reachabilityStatus = status
                switch status {
                case .reachable(let type):
                    logger.debug("Server is reachable using \(type)")
                case .notReachable, .unknown:
                    logger.debug("Server not reachable")
                }
            }
        } else {
            reachabilityTask?.cancel()
            reachabilityTask = nil
            reachabilityStatus = .unknown
        }
    }

}
