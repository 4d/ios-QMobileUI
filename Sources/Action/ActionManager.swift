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

import QMobileAPI

/// Class to execute actions.
public class ActionManager {

    public static let instance = ActionManager()

    // XXX to remove
    private let oldWayParametersNotIndexed = Prephirences.sharedInstance["action.context.merged"] as? Bool ?? false

    var lastContext: ActionContext?

    public var handlers: [ActionResultHandler] = []

    init() {
        // default handlers

        // dataSynchro
        append { result, action, _ in
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
        append { result, _, _ in
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
        append { result, _, _ in
            guard let pasteboard = result.pasteboard else { return false }
            UIPasteboard.general.string = pasteboard
            return true
        }
        append { result, _, _ in
            guard result.goBack else { return false }
            UIApplication.topViewController?.dismiss(animated: true, completion: {

            })

            return true
        }
        #if DEBUG

        append { result, _, actionUI in
            guard let actionSheet = result.actionSheet else { return false }
            let alertController = UIAlertController.build(from: actionSheet, context: self, handler: self.prepareAndExecuteAction)
            _ = alertController.checkPopUp(actionUI)
            alertController.show {

            }
            return true
        }

        append { _, _, _ in
            /*if _ = result.goTo {
             // Open internal
             }*/
             return false
        }

        append { result, _, _ in
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

    /// Execute the action
    func prepareAndExecuteAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        if let actionParameters = action.parameters {

            // TODO #106847 Create UI according to action parameters

            if actionParameters.count == 1 {
                UIAlertController.build(action, actionUI, context, self.handleActiont)

            } else {
                let type: ActionParametersUI.Type = ActionFormViewController.self // ActionParametersController.self
                type.build(action, actionUI, context, self.handleActiont)
            }

        } else {
            // Execute action without any parameters
            executeAction(action, actionUI, context, nil /*without parameters*/)
        }
    }

    typealias ActionExecutionContext = (Action, ActionUI, ActionContext, ActionParameters?)
    func handleActiont(_ result: Result<ActionExecutionContext, ActionParametersUIError>) {
        switch result {
        case .success(let context):
            executeAction(context.0, context.1, context.2, context.3)
        case .failure(let error):
            logger.warning("Action not perfrmed: \(error)")
        }
    }

    func executeAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionParameters: ActionParameters?) {
        self.lastContext = context // keep as last context
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

                    _ = self.handle(result: value, for: action, from: actionUI)
                }
            }
        }
    }

}

extension UITextField {

    func from(actionParameter: ActionParameter, context: ActionContext) {
        self.placeholder = actionParameter.placeholder
        if let defaultValue = actionParameter.defaultValue(with: context) {
            self.text = "\(defaultValue)"
        }
        if let format = actionParameter.format {
            switch format {
            case .email/* .emailAddress*/:
                self.keyboardType = .emailAddress
                return
            case .url:
                self.keyboardType = .URL
                return
            case .phone:
                self.keyboardType = .phonePad
                return
            default:
                break
            }
        }
        switch actionParameter.type {
        case .string, .text:
            self.keyboardType = .default
        case .real, .number:
            self.keyboardType = .decimalPad
        case .integer:
            self.keyboardType = .numberPad // XXX test it numbersAndPunctuation
        default:
            self.keyboardType = .default
        }
    }

}

extension Action {
    static let dummy =  Action(name: "")
}

extension ActionManager: ActionContext {
    public func actionParameters(action: Action) -> ActionParameters? {
        return lastContext?.actionParameters(action: action) // JUST for test purpose make it implement it, maybe return last action parameters
    }

    public func actionParameterValue(for field: String) -> Any? {
        return lastContext?.actionParameterValue(for: field)
    }
}

extension ActionManager: ActionResultHandler {

    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI) -> Bool {
        var handled = false
        for handler in handlers {
            handled = handler.handle(result: result, for: action, from: actionUI) || handled
        }
        return handled
    }
}

/*extension UIActivityViewController {
    func show(_ viewControllerToPresent: UIViewController? = UIApplication.topViewController, animated flag: Bool = true, completion: (() -> Swift.Void)? = nil) {
        viewControllerToPresent?.present(self, animated: flag, completion: completion)
    }
}*/

/// Handle an action results.
public protocol ActionResultHandler {
    typealias Block = (ActionResult, Action, ActionUI) -> Bool
    func handle(result: ActionResult, for action: Action, from: ActionUI) -> Bool
}

/// Handle action result with a block
public struct ActionResultHandlerBlock: ActionResultHandler {
    var block: ActionResultHandler.Block
    public init(_ block: @escaping ActionResultHandler.Block) {
        self.block = block
    }
    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI) -> Bool {
        return block(result, action, actionUI)
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
    /*fileprivate var action: Action? {
        guard let jsonString = json["action"].rawString(options: []) else {
            return nil
        }
        return Action.decode(fromJSON: jsonString)
    }*/
}
