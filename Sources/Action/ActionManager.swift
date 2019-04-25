//
//  ActionManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftMessages

import QMobileAPI

/// Class to execute actions.
public class ActionManager {

    public static let instance = ActionManager()

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
            let alertController = UIAlertController.build(from: actionSheet, context: self, handler: self.executeAction)
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

    func executeAction(_ action: Action, _ actionUI: ActionUI, _ parameters: ActionParameters?) {
        if let actionParameters = action.parameters, let firstParameter = actionParameters.first {
            // TODO #106847 Create UI according to action parameters

            if actionParameters.count == 1 {
                let alertController = UIAlertController(title: firstParameter.label ?? firstParameter.name, message: nil, preferredStyle: .actionSheet)

                var actionParametersValue: [String: Any] = [:]

                switch firstParameter.type {
                case .string, .text:
                    alertController.addOneTextField { textField in
                        textField.left(image: UIImage(named: "next"), color: .black)
                        textField.leftViewPadding = 12
                        textField.becomeFirstResponder()
                        textField.layer.borderWidth = 1
                        textField.layer.cornerRadius = 8
                        textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
                        textField.backgroundColor = nil
                        textField.textColor = .black
                        textField.placeholder = firstParameter.placeholder
                        textField.keyboardAppearance = .default
                        textField.keyboardType = .default
                        // textField.isSecureTextEntry = true
                        textField.returnKeyType = .done
                        textField.action { textField in
                            logger.debug("textField: \(String(describing: textField.text))")

                            actionParametersValue[firstParameter.name] = textField.text
                        }
                    }
                case .date:
                    alertController.message = "Select a date"
                    alertController.addDatePicker(mode: .date, date: Date()) { date in
                        actionParametersValue[firstParameter.name] = date
                    }
                case .duration, .time:
                    alertController.addDatePicker(mode: .time, date: Date()) { date in
                        actionParametersValue[firstParameter.name] = date
                    }
                case .picture, .image:
                    alertController.addImagePicker(flow: .vertical, paging: true, images: [])
                case .integer, .number, .real:
                    let numberValues: [Int] = (1...100).map { $0 }
                    let pickerViewValues: [[String]] = [numberValues.map { $0.description }]
                    alertController.addPickerView(values: pickerViewValues) { (_, _, index, _) in
                        actionParametersValue[firstParameter.name] = numberValues[index.row]
                    }
                default:
                    break // XXX show notingg
                }

                let validateAction = UIAlertAction(title: "Validate", style: .default) { _ in // XXX
                    var parameters: ActionParameters = parameters ?? [:]

                    // For the moment merge all parameters...
                    parameters.merge(actionParametersValue, uniquingKeysWith: { $1 })

                    self.executeActionRequest(action, actionUI, parameters)
                }
                alertController.addAction(validateAction)

                _ = alertController.checkPopUp(actionUI)
                alertController.show()

            } else {
                let alertController = UIAlertController(title: "Not implemented", message: "Multiple parameters", preferredStyle: .alert)

                alertController.addAction(alertController.dismissAction())
                _ = alertController.checkPopUp(actionUI)
                alertController.show()
            }

        } else {
            // Execute action without any parameters
            executeActionRequest(action, actionUI, parameters)
        }
    }

    func executeActionRequest(_ action: Action, _ actionUI: ActionUI, _ parameters: ActionParameters?) {
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

                    _ = self.handle(result: value, for: action, from: actionUI)
                }
            }
        }
    }

}

extension ActionManager: ActionContext {
    public func actionParameters(action: Action) -> ActionParameters? {
        return nil // JUST for test purpose make it implement it, maybe return last action parameters
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
