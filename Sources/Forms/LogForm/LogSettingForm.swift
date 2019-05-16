//
//  LogSettingForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 18/07/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit
import XCGLogger

@IBDesignable
open class LogSettingForm: UITableViewController {

    @IBOutlet weak var levelPicker: UIPickerView!

    var levels = XCGLogger.Level.allCases

    var logFormatter: ApplicationLogger.LogFormatter = .emoticon

    open override func viewDidLoad() {
        levelPicker.dataSource = self
        levelPicker.delegate = self
    }

    open override func viewDidAppear(_ animated: Bool) {
        let currentLevel = logger.outputLevel
        if let index = levels.firstIndex(of: currentLevel) {
            levelPicker.selectRow(index, inComponent: 0, animated: animated)
        }
    }

}

extension LogSettingForm: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return levels.count
    }
}

extension LogSettingForm: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let level = levels[row]

        var title = level.description
        if let prefixes = logFormatter.prefixes, let prefix = prefixes[level] {
            title = prefix + title
        }

        return NSAttributedString(string: title)
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let level = levels[row]
        logger.outputLevel = level
        // XXX save for next run?
    }
}
