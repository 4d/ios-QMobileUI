//
//  ActionManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import SwiftMessages
import Prephirences
import Eureka
import BrightFutures

import QMobileAPI

/// Class to execute actions.
public class ActionManager {

    public static let instance = ActionManager()

    // XXX to remove
    private let oldWayParametersNotIndexed = Prephirences.sharedInstance["action.context.merged"] as? Bool ?? false

    public var handlers: [ActionResultHandler] = []

    init() {
        // default handlers

        // Show log
        append { result, _, _, _ in
            logger.debug("Action result \(result.json)")
            return true
        }

        // Show message as info message
        append { result, _, _, _ in
            guard let statusText = result.statusText else { return false }
            SwiftMessages.info(statusText)
            return true
        }

        // dataSynchro
        append { result, action, _, _ in
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

        // openURL
        append { result, _, _, _ in
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
        // Copy test to pasteboard
        append { result, _, _, _ in
            guard let pasteboard = result.pasteboard else { return false }
            UIPasteboard.general.string = pasteboard
            return true
        }
        append { result, _, _, _ in
            guard result.goBack else { return false }
            UIApplication.topViewController?.dismiss(animated: true, completion: {

            })

            return true
        }

        append { result, _, actionUI, context in
            guard let actionSheet = result.actionSheet else { return false }
            onForeground {
                let alertController = UIAlertController.build(from: actionSheet, context: context, handler: self.prepareAndExecuteAction)
                _ = alertController.checkPopUp(actionUI)
                alertController.show {

                }
            }
            return true
        }

        append { result, _, actionUI, context in
            guard let action = result.action else { return false }
            onForeground {
                self.prepareAndExecuteAction(action, actionUI, context)
            }
            return true
        }

        #if DEBUG
        append { _, _, _, _ in
            /*if _ = result.goTo {
             // Open internal
             }*/
            return false
        }

        append { result, _, _, _ in
            guard result.share else { return false }
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
            return false
        }
        #endif
    }

    public func append(_ block: @escaping ActionResultHandler.Block) {
        handlers.append(ActionResultHandlerBlock(block))
    }

    /// Execute the action.
    /// If there is parameters show a form.
    public func prepareAndExecuteAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        if action.parameters.isEmpty {
            // Execute action without any parameters
            executeAction(action, actionUI, context, nil /*without parameters*/, nil)
        } else {
            // Create UI according to action parameters
            var control: ActionParametersUIControl?
            if ActionFormSettings.alertIfOneField {
                control = UIAlertController.build(action, actionUI, context, self.executeAction) // could return nil if not managed
            }

            if control == nil {
                let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
                control = type.build(action, actionUI, context, self.executeAction)
            }
            control?.showActionParameters()
        }
    }

    typealias ActionExecutionCompletionHandler = ((Result<ActionResult, APIError>) -> Future<ActionResult, APIError>)
    typealias ActionExecutionContext = (Action, ActionUI, ActionContext, ActionParameters?, ActionExecutionCompletionHandler?)

    /// Execute action if success.
    func executeAction(_ result: Result<ActionExecutionContext, ActionParametersUIError>) {
        switch result {
        case .success(let context):
            executeAction(context.0, context.1, context.2, context.3, context.4)
        case .failure(let error):
            logger.warning("Action not performed: \(error)")
        }
    }

    /// Execute the network call for action.
    func executeAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionParameters: ActionParameters?, _ completionHandler: ActionExecutionCompletionHandler?) {
       // self.lastContext = context // keep as last context
        // execute the network action
        // For the moment merge all parameters...
        var parameters: ActionParameters = [:]
        if let actionParameters = actionParameters {
            if oldWayParametersNotIndexed {
                parameters = actionParameters // old way
            } else {
                parameters["parameters"] = actionParameters // new way #107204
            }
        }
        if let contextParameters = context.actionParameters(action: action) {
            if oldWayParametersNotIndexed {
                parameters.merge(contextParameters, uniquingKeysWith: { $1 })
            } else {
                parameters["context"] = contextParameters
            }
        }
        let actionQueue: DispatchQueue = .background
        actionQueue.async {
            logger.info("Launch action \(action.name) with context and parameters: \(parameters)")
            _ = APIManager.instance.action(action, parameters: parameters, callbackQueue: .background) { (result) in
                // Display result or do some actions (incremental etc...)
                switch result {
                case .failure(let error):
                    logger.warning("Action error: \(error)")

                    if !Prephirences.Auth.Login.form, error.isHTTPResponseWith(code: .unauthorized) {
                        ApplicationAuthenticate.retryGuestLogin { authResult in
                            switch authResult {
                            case .success:
                                // XXX do not do infinite retry
                                self.executeAction(action, actionUI, context, actionParameters, completionHandler)
                            case .failure(let authError):
                                self.showError(authError)
                               _ = completionHandler?(.failure(error))
                            }
                        }
                        return
                    }
                    self.showError(error)
                    _ = completionHandler?(.failure(error))
                case .success(let value):
                    logger.debug("\(value)")
                    if let completionHandler = completionHandler {
                        let future = completionHandler(.success(value))
                        // delay handle action result, after form finish with it
                        future.onComplete { result in
                            onForeground {
                                background {
                                    _ = self.handle(result: value, for: action, from: actionUI, in: context)
                                }
                            }
                        }
                    } else {
                        onForeground {
                            background {
                                _ = self.handle(result: value, for: action, from: actionUI, in: context)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Show error has status text.
    func showError(_ error: APIError) {
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
    }

}

extension UITextField {

    func from(actionParameter: ActionParameter, context: ActionContext) {
        self.placeholder = actionParameter.placeholder
        if let defaultValue = actionParameter.defaultValue(with: context) {
            self.text = "\(defaultValue)"
        }
        self.keyboardType = actionParameter.keyboardType(with: context)
    }

}

extension ActionParameter {

    func keyboardType(with context: ActionContext) -> UIKeyboardType {
        if let format = self.format {
            switch format {
            case .email/* .emailAddress*/:
                return .emailAddress
            case .url:
                return .URL
            case .phone:
                return .phonePad
            default:
                break
            }
        }
        switch self.type {
        case .string, .text:
            return .default
        case .real, .number:
            return .decimalPad
        case .integer:
            return .numberPad
        default:
            return .default
        }
    }

}

extension Action {
    static let dummy =  Action(name: "")
}

// MARK: ActionResultHandler

extension ActionManager: ActionResultHandler {

    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        var handled = false
        for handler in handlers {
            handled = handler.handle(result: result, for: action, from: actionUI, in: context) || handled
        }
        return handled
    }
}

/// Handle an action results.
public protocol ActionResultHandler {
    typealias Block = (ActionResult, Action, ActionUI, ActionContext) -> Bool
    func handle(result: ActionResult, for action: Action, from: ActionUI, in context: ActionContext) -> Bool
}

/// Handle action result with a block
public struct ActionResultHandlerBlock: ActionResultHandler {
    var block: ActionResultHandler.Block
    public init(_ block: @escaping ActionResultHandler.Block) {
        self.block = block
    }
    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        return block(result, action, actionUI, context)
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
    fileprivate var goTo: String? {
        return json["goTo"].string
    }
    fileprivate var goBack: Bool {
        return json["goBack"].boolValue
    }
    fileprivate var actionSheet: ActionSheet? {
        if json["actions"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return ActionSheet.decode(fromJSON: jsonString)
    }

    fileprivate var action: Action? {
        if json["parameters"].isEmpty {
            return nil
        }
        guard let jsonString = json.rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }
    /*fileprivate var action: Action? {
        guard let jsonString = json["action"].rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }*/

    typealias Validation = (String?, ValidationError)

    fileprivate var validationErrors: [Validation]? {
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
