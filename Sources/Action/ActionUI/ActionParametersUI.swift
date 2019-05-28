//
//  ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI

/// UI to fill action parameters.
protocol ActionParametersUI {
    typealias CompletionHandler = (Result<ActionManager.ActionExecutionContext, ActionParametersUIError>) -> Void
    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler)
}

/// All errors if action parameters cannot be computed
enum ActionParametersUIError: Error {
    case noParameters
    case wrongNumberOfParameters
    case userCancel
}

/// Custom implementation

class ActionParametersController: UIViewController, ActionParametersUI {

    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        let viewController = ActionParametersController(action, actionUI, context, completionHandler)
        let navigationController = viewController.embedIntoNavigationController()
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.show()
    }

    var actionParametersValue: [String: Any] = [:]

    var action: Action = .dummy
    var actionUI: ActionUI = UIAlertAction(title: "", style: .default, handler: nil)
    var context: ActionContext = UIView()
    var completionHandler: CompletionHandler = { result in }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        self.init(nibName: nil, bundle: nil)
        self.action = action
        self.actionUI = actionUI
        self.context = context

        self.completionHandler = completionHandler

        self.title = action.preferredLongLabel
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
        self.dismiss(animated: true) {
            self.completionHandler(.success((self.action, self.actionUI, self.context, self.actionParametersValue)))
        }
    }

    @objc func dismissAction(sender: Any!) {
        self.dismiss(animated: true) {
            self.completionHandler(.failure(.userCancel))
        }
    }

}
