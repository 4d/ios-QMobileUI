//
//  ActionUIManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftMessages

import QMobileAPI

/// Class to execute actions.
class ActionUIManager {

    /// Execute the action
    static func executeAction(_ action: Action, _ actionUI: ActionUI, _ parameters: ActionParameters?) {
        // execute the network action
        let parameters = parameters ?? [:]
        let actionQueue: DispatchQueue = .background
        actionQueue.async {
            logger.info("Launch action \(action.name) on context: \(parameters)")
            _ = APIManager.instance.action(action, parameters: parameters, callbackQueue: .background) { (result) in
                // Display result or do some actions (incremental etc...)
                switch result {
                case .failure(let error):
                    logger.warning("Action error: \(error)")

                    // Try to display the best error message...
                    if let statusText = error.restErrors?.statusText { // dev message
                        SwiftMessages.error(title: error.errorDescription ?? "", message: statusText)
                    } else /*if apiError.isRequestCase(.connectionLost) ||  apiError.isRequestCase(.notConnectedToInternet) {*/ // not working always
                        if !ApplicationReachability.isReachable { // so check reachability status
                            SwiftMessages.error(title: "", message: "Please check your network settings and data cover...") // CLEAN factorize with data sync error message...
                        } else if let failureReason = error.failureReason {
                            SwiftMessages.warning(failureReason)
                        } else {
                            SwiftMessages.error(title: error.errorDescription ?? "", message: "")
                    }
                case .success(let value):
                    logger.debug("\(value)")

                    if let statusText = value.statusText {
                        SwiftMessages.info(statusText)
                    }

                    // launch incremental sync? or other task
                    if value.dataSynchro {
                        logger.info("Data synchronisation is launch after action \(action.name)")
                        _ = dataSync { result in
                            switch result {
                            case .failure(let error):
                                logger.warning("Failed to do data synchro after action \(action.name): \(error)")
                            case .success:
                                logger.warning("Data synchro after action \(action.name) success")
                            }
                        }
                    }

                    if let urlString = value.openURL, let url = URL(string: urlString) {
                        logger.info("Open url \(urlString)")
                        UIApplication.shared.open(url, options: [:], completionHandler: { success in
                            if success {
                                logger.info("Open url \(urlString) done")
                            } else {
                                logger.warning("Failed to pen url \(urlString)")
                            }
                        })
                    }

                    if value.share {
                        // Remote could send from server
                        // * some text
                        // * some url
                        // * data of image -> convert to image and share
                        // * data of file -> write to tmp dir and share
                        //
                        // then could also specify local db data
                        // * some text or number field to share as string
                        // * some picture field to share (must be downloaded before)
                        // * some text field to share as url

                        // URL (http url or file url), UIImage, String
                        /*let activityItems: [Any] = ["Hello, world!"]
                        // , UIImage(named: "tableMore") ?? nil
                        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
                        activityViewController.show()*/
                    }

                    if let pasteboard = value.pasteboard {
                        UIPasteboard.general.string = pasteboard
                    }
                }
            }
        }
    }
}

extension UIActivityViewController {
    func show(_ viewControllerToPresent: UIViewController? = UIApplication.topViewController, animated flag: Bool = true, completion: (() -> Swift.Void)? = nil) {
        viewControllerToPresent?.present(self, animated: flag, completion: completion)
    }
}

extension ActionResult {
    /// Return: `true` if a data synchronisation must be done after the action.
    fileprivate var dataSynchro: Bool {
        return json["dataSynchro"].boolValue
    }
    fileprivate var openURL: String? {
        return json["openURL"].string
    }
    fileprivate var share: Bool {
        return json["share"].boolValue
    }
    fileprivate var pasteboard: String? {
        return json["pasteboard"].string
    }
}
