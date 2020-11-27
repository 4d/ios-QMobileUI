import UIKit

// MARK: date picker

extension UIAlertController {

    func addDatePicker(mode: UIDatePicker.Mode, date: Date?, minimumDate: Date? = nil, maximumDate: Date? = nil, style: UIDatePickerStyle = .wheels, action: DatePickerViewController.Action?) {
        let datePicker = DatePickerViewController(mode: mode, date: date, minimumDate: minimumDate, maximumDate: maximumDate, style: style, action: action)
        set(viewController: datePicker, height: 217)
    }
}

// MARK: controller

final class DatePickerViewController: UIViewController {

    public typealias Action = (Date) -> Void

    fileprivate var action: Action?

    fileprivate lazy var datePicker: UIDatePicker = { [unowned self] in
        $0.addTarget(self, action: #selector(DatePickerViewController.actionForDatePicker), for: .valueChanged)
        return $0
    }(UIDatePicker())

    required init(mode: UIDatePicker.Mode, date: Date? = nil, minimumDate: Date? = nil, maximumDate: Date? = nil, style: UIDatePickerStyle, action: Action?) {
        super.init(nibName: nil, bundle: nil)
        datePicker.datePickerMode = mode
        datePicker.date = date ?? Date()
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        datePicker.preferredDatePickerStyle = style
        self.action = action
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = datePicker
    }

    @objc func actionForDatePicker() {
        action?(datePicker.date)
    }

    public func setDate(_ date: Date) {
        datePicker.setDate(date, animated: true)
    }
}
