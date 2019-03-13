//
//  ActionUI.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 05/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

/// An action ui element could be builded from action and context and on action launch the passed handler.
public protocol ActionUI {

    typealias Handler = (Action, ActionUI, ActionContext) -> Void

    /// Build an action ui element.
    static func build(from action: Action, context: ActionContext, handler: @escaping Handler) -> ActionUI
}

/// An action context provide parameters for action.
public protocol ActionContext {

    /// Provide parameters for the action.
    func actionParameters(action: Action, actionUI: ActionUI) -> ActionParameters?

}

/// Simplement implementation of `ActionContext`
struct ActionParametersContext: ActionContext {

    var actionParameters: ActionParameters?

    func actionParameters(action: Action, actionUI: ActionUI) -> ActionParameters? {
        return actionParameters
    }
}

/// Builder class to force cast
struct ActionUIBuilder {
    static func build<T>(_ type: T.Type, from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> T? where T: ActionUI {
        return type.build(from: action, context: context, handler: handler) as? T
    }

    /// Provide an image for the passed action.
    static func actionImage(for action: Action) -> UIImage? {
        guard let icon = action.icon else {
            return nil
        }
        return UIImage(named: icon)
    }

    /// Provide a color for the passed action.
    static func actionColor(for action: Action) -> UIColor? {
        guard let style = action.style else {
            return nil
        }
        switch style {
        case .color(let named):
            return UIColor(named: named)
        default:
            break
        }
        return nil
    }
}

public protocol ActionSheetUI {
    //associatedtype ActionUIItem: ActionUI // XXX swift generic do not work well with objc dynamic and storyboards
    func actionUIType() -> ActionUI.Type

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI]
    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI?

    func addActionUI(_ item: ActionUI?)
}

public extension ActionSheetUI {

    func build(from actionSheet: ActionSheet, context: ActionContext, handler: @escaping ActionUI.Handler) -> [ActionUI] {
        return actionSheet.actions.compactMap {
            actionUIType().build(from: $0, context: context, handler: handler)
        }
    }

    func build(from action: Action, context: ActionContext, handler: @escaping ActionUI.Handler) -> ActionUI? {
        return actionUIType().build(from: action, context: context, handler: handler)
    }

    func addActionUIs(_ items: [ActionUI]) {
        for item in items {
            addActionUI(item)
        }
    }
}

import SwiftMessages

class ActionUIManager {

    /// Execute the action
    static func executeAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {

        // Get parameters for network actions
        let parameters: ActionParameters = context.actionParameters(action: action, actionUI: actionUI) ?? [:]

        // execute the network action
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
                        let activityItems: [Any] = ["Hello, world!"]
                        // , UIImage(named: "tableMore") ?? nil
                        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
                        activityViewController.show()
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
}