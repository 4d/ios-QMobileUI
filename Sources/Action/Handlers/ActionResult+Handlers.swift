//
//  ActionResult+ActionManager.swift
//  QMobileUI
//
//  Created by phimage on 05/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

import Eureka
import SwiftMessages

extension ActionResult {

    var goTo: String? {
        return json["goTo"].string
    }

    var goBack: Bool {
        return json["goBack"].boolValue
    }

    /*fileprivate var action: Action? {
     guard let jsonString = json["action"].rawString(options: []) else {
     return nil
     }
     return Action.decode(fromJSON: jsonString)
     }*/

    typealias Validation = (String?, ValidationError)

    var validationErrors: [Validation]? {
        guard let errors = json["validationErrors"].arrayObject else {
            return nil
        }

        return errors.compactMap { (object: Any) -> Validation? in
            if let message = object as? String {
                return (nil, ValidationError(msg: message))
            } else if let dictionary = object as? [String: String],
                      let message = dictionary["message"],
                      let field = dictionary["field"] {
                return (field, ValidationError(msg: message))
            }
            return nil
        }
    }
}

extension ActionResult {

    // Show message as info message
    static var statusTextBlock: ActionResultHandler.Block {
        return {result, _, actionUI, _ in
            guard let statusText = result.statusText else { return false }
            if result.success {
                SwiftMessages.info(statusText)
            } else {
                SwiftMessages.warning(statusText)
            }
            return true
        }
    }
}

extension ActionResult {

    /// Return: `true` if a data synchronisation must be done after the action.
    var dataSynchro: Bool {
        return json["dataSynchro"].boolValue
    }

    static var dataSynchroBlock: ActionResultHandler.Block {
        return { result, action, _, _ in
            guard result.dataSynchro else { return false }
            logger.info("Data synchronisation is launch after action \(action.name)")
            _ = dataSync { result in
                switch result {
                case .failure(let error):
                    logger.warning("Failed to do data synchro after action \(action.name): \(error)")
                case .success:
                    logger.info("Data synchro after action \(action.name) success")
                }
            }
            return true
        }
    }
}

extension ActionResult {

    var openURL: String? {
        return json["openURL"].string
    }

    // openURL
    static var openURLBlock: ActionResultHandler.Block {
        return { result, _, _, _ in
            guard let urlString = result.openURL, let url = URL(string: urlString) else { return false }
            logger.info("Open url \(urlString)")
            onForeground {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if success {
                        logger.info("Open url \(urlString) done")
                    } else {
                        logger.warning("Failed to open url \(urlString)")
                    }
                })
            }
            return true
        }
    }
}

extension ActionResult {

    var pasteboard: String? {
        return json["pasteboard"].string
    }

    // Copy test to pasteboard
    static var pasteboardBlock: ActionResultHandler.Block {
        return { result, _, _, _ in
            guard let pasteboard = result.pasteboard else { return false }
            UIPasteboard.general.string = pasteboard
            return true
        }
    }
}

extension ActionResult {

    var share: [JSON]? {
        return json["share"].array
    }

    static var shareBlock: ActionResultHandler.Block {
        { result, _, actionUI, _ in
            guard let share = result.share else { return false }
            let activityItems: [Any] = share.compactMap { item in
                if let itemInfo = item.dictionary, let value = itemInfo["value"] {
                    if let type = itemInfo["type"]?.string {
                        switch type {
                        case "url":
                            return URL(string: value.stringValue)
                        case "image":
                            if let url = URL(string: value.stringValue) {
                                if let data = try? Data(contentsOf: url) {
                                    return UIImage(data: data)
                                }
                                return url
                            }
                            return value.rawValue
                        default:
                            return value.rawValue
                        }
                    } else {
                        return value.rawValue
                    }
                } else {
                    return item.rawValue
                }
            }

            foreground {
                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                activityViewController.checkPopUp(actionUI)

                activityViewController.show(animated: true) {
                    logger.info("Share activity presented")
                }
            }
            return true
        }
    }
}

import Alamofire

extension ActionResult {

    var downloadURL: String? {
        return json["downloadURL"].string
    }

    static var downloadURLBlock: ActionResultHandler.Block {
        return { result, _, actionUI, _ in
            guard let urlString = result.downloadURL, let url = URL(string: urlString) else { return false }
            logger.info("Download url \(urlString)")

            AF.request(url).responseData { response in
                if let fileData = response.data {
                    foreground {
                        let activityViewController = UIActivityViewController(activityItems: [url.lastPathComponent, fileData], applicationActivities: nil)
                        activityViewController.checkPopUp(actionUI)
                        activityViewController.show(animated: true) {
                            logger.info("End to download \(url)")
                        }
                    }
                }
            }
            return true
        }
    }
}

extension ActionResult {

    var deepLink: DeepLink? {
        return DeepLink.from(json)
    }

    static var deepLinkBlock: ActionResultHandler.Block {
        return { result, _, _, _ in
            guard let deepLink = result.deepLink else { return false }
            logger.info("Deeplink from action: \(deepLink)")
            foreground {
                ApplicationCoordinator.open(deepLink) { _ in }
            }
            return true
         }
    }
}

extension ActionResult {

    var actionSheet: QMobileAPI.ActionSheet? {
        if json["actions"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return ActionSheet.decode(fromJSON: jsonString)
    }

    static func actionSheetBlock(_ prepareAndExecuteAction: @escaping ActionUI.Handler) -> ActionResultHandler.Block {
        return { result, _, actionUI, context in
            guard let actionSheet = result.actionSheet else { return false }
            onForeground {
                let alertController = UIAlertController.build(from: actionSheet, context: context, handler: prepareAndExecuteAction)
                _ = alertController.checkPopUp(actionUI)
                alertController.show {

                }
            }
            return true
        }
    }
}

extension ActionResult {

    var action: Action? {
        if json["parameters"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }

    static func actionBlock(_ prepareAndExecuteAction: @escaping ActionUI.Handler) -> ActionResultHandler.Block {
        return { result, _, actionUI, context in
            guard let action = result.action else { return false }
            onForeground {
                prepareAndExecuteAction(action, actionUI, context)
            }
            return true
        }
    }
}
