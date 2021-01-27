//
//  TimeRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Eureka

open class _TimeIntervalRow: _TimeIntervalFieldRow { // swiftlint:disable:this type_name
    required public init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .short
        dateFormatter?.dateStyle = .none
        dateFormatter?.locale = Locale.current
        dateFormatter?.timeZone = .greenwichMeanTime
    }
}

open class _CountDownTimeRow: _TimeIntervalFieldRow { // swiftlint:disable:this type_name
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value else {
                return nil
            }
            self.dateFormatter?.timeZone = .greenwichMeanTime
            if let formatter = self.dateFormatter {
                return formatter.string(from: Date(timeIntervalSinceReferenceDate: val))
            }

            let dateComponents = Calendar.iso8601GreenwichMeanTime.dateComponents([.hour, .minute/*, .second*/], from: Date(timeInterval: val))
            return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "")
        }
    }
}

/// A row with an Date as value where the user can select a time from a picker view.
public final class TimeIntervalRow: _TimeIntervalRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row with an Date as value where the user can select hour and minute as a countdown timer in a picker view.
public final class CountDownTimeRow: _CountDownTimeRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _TimeIntervalFieldRow: Row<TimeIntervalCell>, TimeIntervalPickerRowProtocol, NoValueDisplayTextConformance { // swiftlint:disable:this type_name

    /// The minimum value for this row's UIDatePicker
    open var minimumTime: TimeInterval?

    /// The maximum value for this row's UIDatePicker
    open var maximumTime: TimeInterval?

    /// The interval between options for this row's UIDatePicker
    open var minuteInterval: Int?

    /// The formatter for the date picked by the user
    open var dateFormatter: DateFormatter?

    open var noValueDisplayText: String?

    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value, let formatter = self.dateFormatter else { return nil }
            return formatter.string(from: Date(timeIntervalSinceReferenceDate: val))
        }
    }
}

// MARK: cell

public protocol TimeIntervalPickerRowProtocol: class {
    var minimumTime: TimeInterval? { get set }
    var maximumTime: TimeInterval? { get set }
    var minuteInterval: Int? { get set }
}

extension TimeIntervalPickerRowProtocol {
    var minimumDate: Date? {
        guard let time = minimumTime else { return nil }
        return Date(timeInterval: time)
    }
    var maximumDate: Date? {
        guard let time = maximumTime else { return nil }
        return Date(timeInterval: time)
    }
}

open class TimeIntervalCell: Cell<TimeInterval>, CellType {

    public var datePicker: UIDatePicker

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        datePicker = UIDatePicker()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        datePicker = UIDatePicker()
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType =  .none
        datePicker.datePickerMode = datePickerMode()
        datePicker.addTarget(self, action: #selector(TimeIntervalCell.datePickerValueChanged(_:)), for: .valueChanged)
        datePicker.timeZone = .greenwichMeanTime
        datePicker.preferredDatePickerStyle = .wheels
    }

    deinit {
        datePicker.removeTarget(self, action: nil, for: .allEvents)
    }

    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        let timeInterval = row.value ?? 0
        let date = Date(timeInterval: timeInterval)
        datePicker.setDate(date, animated: false)
        datePicker.minimumDate = (row as? TimeIntervalPickerRowProtocol)?.minimumDate
        datePicker.maximumDate = (row as? TimeIntervalPickerRowProtocol)?.maximumDate
        if let minuteIntervalValue = (row as? TimeIntervalPickerRowProtocol)?.minuteInterval {
            datePicker.minuteInterval = minuteIntervalValue
            if row is CountDownTimeRow {
                datePicker.countDownDuration = TimeInterval(minuteIntervalValue * 60)
            }
        }
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }
    }

    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }

    override open var inputView: UIView? {
        if let value = row.value {
            if row is CountDownTimeRow {
                datePicker.countDownDuration = TimeInterval(900)

                if value == 0 {
                    if let minuteIntervalValue = (row as? TimeIntervalPickerRowProtocol)?.minuteInterval {
                        datePicker.countDownDuration = TimeInterval(minuteIntervalValue * 60)
                        row.value = TimeInterval(minuteIntervalValue * 60)
                    }
                }
            } else {
                let date = Date(timeInterval: value)
                datePicker.setDate(date, animated: false)
            }
        }
        return datePicker
    }

    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        let date = sender.date
        let timeInterval = date.timeInterval
        row.value = timeInterval
        detailTextLabel?.text = row.displayValueFor?(row.value)
    }

    private func datePickerMode() -> UIDatePicker.Mode {
        switch row {
        case is TimeIntervalRow:
            return .time
        case is CountDownTimeRow:
            return .countDownTimer
        default:
            return .time
        }
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return canBecomeFirstResponder
    }

    override open var canBecomeFirstResponder: Bool {
        return !row.isDisabled
    }
}

extension Date {
    var timeInterval: TimeInterval {
        return self.timeIntervalSinceReferenceDate
    }

    init(timeInterval: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeInterval)
    }
}
