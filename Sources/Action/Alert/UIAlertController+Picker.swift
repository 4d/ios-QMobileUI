import UIKit

extension UIAlertController {

    func addPickerView(values: PickerViewViewController.Values, initialSelection: PickerViewViewController.Index? = nil, action: PickerViewViewController.Action?) {
        let pickerView = PickerViewViewController(values: values, initialSelection: initialSelection, action: action)
        set(viewController: pickerView, height: 216)
    }
}

// MARK: controller

final class PickerViewViewController: UIViewController {

    public typealias Values = [[String]]
    public typealias Index = (column: Int, row: Int)
    public typealias Action = (_ vc: UIViewController, _ picker: UIPickerView, _ index: Index, _ values: Values) -> Void

    fileprivate var action: Action?
    fileprivate var values: Values = [[]]
    fileprivate var initialSelection: Index?

    fileprivate lazy var pickerView: UIPickerView = {
        return $0
    }(UIPickerView())

    init(values: Values, initialSelection: Index? = nil, action: Action?) {
        super.init(nibName: nil, bundle: nil)
        self.values = values
        self.initialSelection = initialSelection
        self.action = action
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("has deinitialized")
    }

    override func loadView() {
        view = pickerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.dataSource = self
        pickerView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let initialSelection = initialSelection, values.count > initialSelection.column, values[initialSelection.column].count > initialSelection.row {
            pickerView.selectRow(initialSelection.row, inComponent: initialSelection.column, animated: true)
        }
    }
}

// MARK: Picker delagates

extension PickerViewViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return values.count
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values[component].count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[component][row]
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action?(self, pickerView, Index(column: component, row: row), values)
    }
}
