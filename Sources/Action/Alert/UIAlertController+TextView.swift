import UIKit

// MARK: set controller
extension UIAlertController {

    func set(viewController: UIViewController?, width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let viewController = viewController else { return }
        setValue(viewController, forKey: "contentViewController")
        if let height = height {
            viewController.preferredContentSize.height = height
            preferredContentSize.height = height
        }
    }

}

// MARK: test fields

extension UIAlertController {

    func addOneTextField(configuration: AlertTextField.Config?) {
        let textField = OneTextFieldViewController(vInset: preferredStyle == .alert ? 12 : 0, configuration: configuration)
        let height: CGFloat = OneTextFieldViewController.SizeConstraints.height + OneTextFieldViewController.SizeConstraints.vInset
        set(viewController: textField, height: height)
    }

    func addTwoTextFields(height: CGFloat = 58, hInset: CGFloat = 0, vInset: CGFloat = 0, textFieldOne: AlertTextField.Config?, textFieldTwo: AlertTextField.Config?) {
        let textField = TwoTextFieldsViewController(height: height, hInset: hInset, vInset: vInset, textFieldOne: textFieldOne, textFieldTwo: textFieldTwo)
        set(viewController: textField, height: height * 2 + 2 * vInset)
    }
}

// MARK: UITextField
class AlertTextField: UITextField {

    typealias Config = (AlertTextField) -> Swift.Void

    public func configure(configurate: Config?) {
        configurate?(self)
    }

    typealias Action = (UITextField) -> Void

    fileprivate var actionEditingChanged: Action?

    // Override
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftViewPadding ?? 0
        return textRect
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: (leftTextPadding ?? 8) + (leftView?.frame.width ?? 0) + (leftViewPadding ?? 0), dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: (leftTextPadding ?? 8) + (leftView?.frame.width ?? 0) + (leftViewPadding ?? 0), dy: 0)
    }

    var leftViewPadding: CGFloat?
    var leftTextPadding: CGFloat?

    func action(closure: @escaping Action) {
        if actionEditingChanged == nil {
            addTarget(self, action: #selector(AlertTextField.textFieldDidChange), for: .editingChanged)
        }
        actionEditingChanged = closure
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        actionEditingChanged?(self)
    }
}

// MARK: Controller

final class OneTextFieldViewController: UIViewController {

    fileprivate lazy var textField: AlertTextField = AlertTextField()

    fileprivate struct SizeConstraints {
        static let height: CGFloat = 44
        static let hInset: CGFloat = 12
        static var vInset: CGFloat = 12
    }

    init(vInset: CGFloat = 12, configuration: AlertTextField.Config?) {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(textField)
        SizeConstraints.vInset = vInset

        textField.height = SizeConstraints.height
        textField.width = view.width

        configuration?(textField)

        preferredContentSize.height = SizeConstraints.height + SizeConstraints.vInset
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        textField.width = view.width - SizeConstraints.hInset * 2
        textField.height = SizeConstraints.height
        textField.center.x = view.center.x
        textField.center.y = view.center.y - SizeConstraints.vInset / 2
    }
}

final class TwoTextFieldsViewController: UIViewController {

    fileprivate lazy var textFieldView = UIView()
    fileprivate lazy var textFieldOne = AlertTextField()
    fileprivate lazy var textFieldTwo = AlertTextField()

    fileprivate var height: CGFloat
    fileprivate var hInset: CGFloat
    fileprivate var vInset: CGFloat

    init(height: CGFloat, hInset: CGFloat, vInset: CGFloat, textFieldOne configurationOneFor: AlertTextField.Config?, textFieldTwo configurationTwoFor: AlertTextField.Config?) {
        self.height = height
        self.hInset = hInset
        self.vInset = vInset
        super.init(nibName: nil, bundle: nil)
        view.addSubview(textFieldView)

        textFieldView.addSubview(textFieldOne)
        textFieldView.addSubview(textFieldTwo)

        textFieldView.width = view.width
        textFieldView.height = height * 2
        textFieldView.layer.masksToBounds = true
        textFieldView.layer.borderWidth = 1
        textFieldView.layer.borderColor = ColorCompatibility.systemGray2.cgColor
        textFieldView.layer.cornerRadius = 8

        configurationOneFor?(textFieldOne)
        configurationTwoFor?(textFieldTwo)

        //preferredContentSize.height = height * 2 + vInset
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        textFieldView.width = view.width - hInset * 2
        textFieldView.height = height * 2
        textFieldView.center.x = view.center.x
        textFieldView.center.y = view.center.y

        textFieldOne.width = textFieldView.width
        textFieldOne.height = textFieldView.height / 2
        textFieldOne.center.x = textFieldView.width / 2
        textFieldOne.center.y = textFieldView.height / 4

        textFieldTwo.width = textFieldView.width
        textFieldTwo.height = textFieldView.height / 2
        textFieldTwo.center.x = textFieldView.width / 2
        textFieldTwo.center.y = textFieldView.height - textFieldView.height / 4
    }
}

extension UITextField {

    public typealias TextFieldConfig = (UITextField) -> Swift.Void

    func left(image: UIImage?, color: UIColor = .black) {
        if let image = image {
            leftViewMode = .always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = color
            leftView = imageView
        } else {
            leftViewMode = .never
            leftView = nil
        }
    }

}
