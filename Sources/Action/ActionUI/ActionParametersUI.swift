//
//  ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileAPI
import Combine

/// UI to fill action parameters.
protocol ActionParametersUI {
    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionExecutor: ActionExecutor) -> ActionParametersUIControl?
}

protocol ActionParametersUIControl {
    func showActionParameters()
    // func dismissActionParameters()
}

extension UIViewController: ActionParametersUIControl {
    func showActionParameters() {
        self.show()
    }

    /*func dismissActionParameters() {
        self.dismiss(animated: true, completion: nil)
    }*/
}

struct ActionParametersUIBuilder {

    var action: Action
    var actionUI: ActionUI
    var context: ActionContext
    var actionExecutor: ActionExecutor
    var id: String // swiftlint:disable:this identifier_name

    init(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionExecutor: ActionExecutor) {
        self.action = action
        self.actionUI = actionUI
        self.context = context
        self.actionExecutor = actionExecutor
        self.id = ActionRequest.generateID(self.action)
    }

    func build<T: ActionParametersUI>(of type: T.Type) -> ActionParametersUIControl? {
        return type.build(action, actionUI, context, actionExecutor)
    }

    fileprivate func executeAction(with parameters: ActionParameters?, waitUI: ActionExecutor.WaitPresenter, completionHandler: ActionExecutor.CompletionHandler?) {
        self.actionExecutor.executeAction(self.action, self.id, self.actionUI, self.context, parameters, waitUI, completionHandler)
    }

    func executeAction(with parameters: ActionParameters?, waitUI: ActionExecutor.WaitPresenter) -> Future<ActionResult, ActionRequest.Error> {
         return Future { promise in
            self.executeAction(with: parameters, waitUI: waitUI, completionHandler: promise)
         }
    }
    private func failWith(error: ActionRequest.Error) -> Future<Void, ActionRequest.Error> {
        return Future { promise in
            promise(.failure(error))
        }
    }
}
/*
/// Custom implementation
class ActionParametersController: UIViewController, ActionParametersUI {

    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionExecutor: ActionExecutor) -> ActionParametersUIControl? {
        let viewController = ActionParametersController(builder: ActionParametersUIBuilder(action, actionUI, context, actionExecutor))
        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        return navigationController
    }

    var actionParametersValue: [String: Any] = [:]

    var builder: ActionParametersUIBuilder?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(builder: ActionParametersUIBuilder) {
        self.init(nibName: nil, bundle: nil)
        self.builder = builder
        self.title = builder.action.preferredLongLabel
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.add(where: .left, item: cancelItem)

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

        guard let parameters = builder?.action.parameters else { return }
        guard let context = builder?.context else { return }
        let frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.width, height: 48))
        let container = stackView
        for parameter in parameters {

            let label = UILabel(frame: frame)
            label.text = parameter.label ?? parameter.shortLabel ?? parameter.name
            container.addArrangedSubview(label)

            let textField = AlertTextField(frame: frame)
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.borderColor = ColorCompatibility.systemGray2.withAlphaComponent(0.5)
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
        button.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
        container.addArrangedSubview(button)

    }

    func dismiss() {
        self.dismiss(animated: true) { [unowned self] in
            self.waiter.send(completion: .finished)
        }
    }
    var waiter: PassthroughSubject<Void, ActionRequest.Error> = PassthroughSubject()

    @objc func doneAction(sender: UIButton!) {
        self.builder?.executeAction(with: self.actionParametersValue, waitUI: self.waiter) { result in

            switch result {
            case .success:
                onForeground {

                }
            case .failure:
                promise(result)
            }
        }
    }

    @objc func cancelAction(sender: Any!) {
        logger.info("Action cancel")
        dismiss()
    }

}*/
