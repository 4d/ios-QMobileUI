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

public protocol ActionUI {
    typealias View = UIView
    typealias Handler = (Action, ActionUI, View) -> Void
    static func build(from action: Action, view: View, handler: @escaping Handler) -> ActionUI
}

/// Builder class to force cast
struct ActionUIBuilder {
    static func build<T>(_ type: T.Type, from action: Action, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> T? where T: ActionUI {
        return type.build(from: action, view: view, handler: handler) as? T
    }

    /// Provide an image for the passed action.
    static func actionImage(for action: Action) -> UIImage? {
        guard let icon = action.icon else {
            return nil
        }
        return UIImage(named: icon) // XXX maybe add prefix
    }

    /// Provide a color for the passed action.
    static func actionColor(for action: Action) -> UIColor? {
        return nil
    }
}

public protocol ActionSheetUI {
    //associatedtype ActionUIItem: ActionUI // XXX swift generic do not work well with objc dynamic and storyboards
    func actionUIType() -> ActionUI.Type

    func build(from actionSheet: ActionSheet, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> [ActionUI]
    func build(from action: Action, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> ActionUI?

    func addActionUI(_ item: ActionUI?)
}

public extension ActionSheetUI {

    func build(from actionSheet: ActionSheet, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> [ActionUI] {
        return actionSheet.actions.compactMap {
            actionUIType().build(from: $0, view: view, handler: handler)
        }
    }

    func build(from action: Action, view: ActionUI.View, handler: @escaping ActionUI.Handler) -> ActionUI? {
        return actionUIType().build(from: action, view: view, handler: handler)
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
    static func executeAction(_ action: Action, _ actionUI: ActionUI, _ view: ActionUI.View) {

        // CLEAN: move this code to a specific controller

        // TODO get parameters for network actions
        var parameters: ActionParameters = ActionParameters()

        if let provider = view.findActionContext(action, actionUI) {
            parameters = provider.actionContext(action: action, actionUI: actionUI) ?? [:]
        }

        // execute the network action
        let actionQueue: DispatchQueue = .background
        actionQueue.async {
            logger.info("Launch action \(action.name) on context: \(parameters)")
            _ = APIManager.instance.action(action, parameters: parameters, callbackQueue: .main) { (result) in
                // Display result or do some actions (incremental etc...)
                switch result {
                case .failure(let error):
                    logger.warning("Action error: \(error)")
                    /*   let alertController = UIAlertController(title: action.label, message: "\(error)", preferredStyle: .alert)
                     alertController.addAction(alertController.dismissAction(title: "Done"))
                     alertController.show()*/

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
                    // TODO launch incremental sync? or other task
                }
            }
        }
    }
}

extension ActionResult {
    /// Return: `true` if a data synchronisation must be done after the action.
    fileprivate var dataSynchro: Bool {
        return json["dataSynchro"].boolValue
    }
}
