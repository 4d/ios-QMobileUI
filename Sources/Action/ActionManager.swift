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
import Prephirences

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
    func executeAction(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        if let actionParameters = action.parameters, let firstParameter = actionParameters.first {
            // TODO #106847 Create UI according to action parameters

            if actionParameters.count == 1 {
                alertAction(firstParameter, action, actionUI, context)

            } else {
                let viewController = ActionParametersController(action, actionUI, context)
                let navigationController = viewController.embedIntoNavigationController()
                navigationController.navigationBar.prefersLargeTitles = false
                navigationController.show()
            }

        } else {
            // Execute action without any parameters
            executeActionRequest(action, actionUI, context, nil /*without parameters*/)
        }
    }

    func executeActionRequest(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionParameters: ActionParameters?) {
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

    fileprivate func alertAction(_ parameter: ActionParameter, _ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        let alertController = UIAlertController(title: parameter.label ?? parameter.name, message: nil, preferredStyle: .actionSheet)

        var actionParametersValue: [String: Any] = [:]

        switch parameter.type {
        case .string, .text, .email:
            alertController.addOneTextField { textField in
                textField.left(image: UIImage(named: "next"), color: .black)
                textField.leftViewPadding = 12

                textField.becomeFirstResponder()

                textField.borderWidth = 1
                textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
                textField.layer.cornerRadius = 8
                textField.backgroundColor = nil
                textField.textColor = .black

                textField.keyboardAppearance = .default
                textField.returnKeyType = .done

                textField.from(actionParameter: parameter, context: context)

                // textField.isSecureTextEntry = true
                textField.action { textField in
                    logger.debug("textField: \(String(describing: textField.text))")
                    actionParametersValue[parameter.name] = textField.text
                }
            }
        case .date:
            alertController.message = "Select a date"
            alertController.addDatePicker(mode: .date, date: Date()) { date in
                actionParametersValue[parameter.name] = date
            }
        case .duration, .time:
            alertController.addDatePicker(mode: .time, date: Date()) { date in
                actionParametersValue[parameter.name] = date
            }
        case .picture, .image:
            // XXX list of images from library?
            alertController.addImagePicker(flow: .vertical, paging: true, images: [])
        case .integer, .number, .real:
            let numberValues: [Int] = (1...100).map { $0 }
            let pickerViewValues: [[String]] = [numberValues.map { $0.description }]
            alertController.addPickerView(values: pickerViewValues) { (_, _, index, _) in
                actionParametersValue[parameter.name] = numberValues[index.row]
            }
        default:
            break // XXX show notingg
        }

        let validateAction = UIAlertAction(title: "Done", style: .default) { _ in // XXX
            self.executeActionRequest(action, actionUI, context, actionParametersValue)
        }
        alertController.addAction(validateAction)

        _ = alertController.checkPopUp(actionUI)
        alertController.show()
    }

}

extension UITextField {

    func from(actionParameter: ActionParameter, context: ActionContext) {
        self.placeholder = actionParameter.placeholder
        if let defaultValue = actionParameter.defaultValue(with: context) {
            self.text = "\(defaultValue)"
        }

        switch actionParameter.type {
        case .string, .text:
            self.keyboardType = .default
        case .real, .number:
            self.keyboardType = .decimalPad
        case .integer:
            self.keyboardType = .numberPad // XXX test it numbersAndPunctuation
        case .email, .emailAddress:
            self.keyboardType = .emailAddress
        case .url:
            self.keyboardType = .URL
        case .phone:
            self.keyboardType = .phonePad
        default:
            self.keyboardType = .default
        }
    }

}

extension Action {
    static let dummy =  Action(name: "")
}

class ActionParametersController: UIViewController {

    var actionParametersValue: [String: Any] = [:]

    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = ActionManager.instance

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext) {
        self.init(nibName: nil, bundle: nil)
        self.action = action
        self.actionUI = actionUI
        self.context = context

        self.title = action.label ?? action.shortLabel ?? action.name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let backItem = UIBarButtonItem(image: UIImage(named: "previous"), style: .plain, target: self, action: #selector(dismissAction))
        self.navigationItem.add(where: .left, item: backItem)

        view.backgroundColor = .white // XXX THEME action parameters depending of the theme

        // Create the scroll view
        let scrollView = UIScrollView()
        let inset: CGFloat = 20 // inset for text field etc...
        scrollView.contentInset.left = inset
        scrollView.contentInset.right = inset
        view.addSubview(scrollView)
        scrollView.snap(to: self.view.safeAreaLayoutGuide) // if issue, use heightAnchor instead of bottom one

        // Create the container stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        scrollView.addSubview(stackView)
        stackView.snap(to: scrollView)
        stackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor, constant: -inset*2).isActive = true

        guard let parameters = action.parameters else { return }
        let frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.width, height: 48))
        let container = stackView
        for parameter in parameters {

            let label = UILabel(frame: frame)
            label.text = parameter.label ?? parameter.shortLabel ?? parameter.name
            container.addArrangedSubview(label)

            let textField = AlertTextField(frame: frame)
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = nil
            textField.action { _ in
                self.actionParametersValue[parameter.name] = textField.text
            }
            textField.from(actionParameter: parameter, context: context)
            self.actionParametersValue[parameter.name] = textField.text // send default value?
            container.addArrangedSubview(textField)
        }

        let button = UIButton(frame: frame)
        button.setTitle("validate", for: .normal)
        button.backgroundColor = .background
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        container.addArrangedSubview(button)

    }

    @objc func buttonAction(sender: UIButton!) {
        ActionManager.instance.executeActionRequest(action, actionUI, context, actionParametersValue)
        self.dismiss(animated: true, completion: nil)
    }

    @objc func dismissAction(sender: Any!) {
        self.dismiss(animated: true, completion: nil)
    }

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
