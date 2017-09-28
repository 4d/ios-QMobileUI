//
//  SettingURLForm.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 12/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences
import QMobileAPI
import QMobileUI

public class SettingURLForm: UITableViewController {

    enum Section: Int {
        case server
    }

    @IBOutlet weak var serverURLTextField: UITextField!

    private var _serverStatusFooter: SettingsServerSectionFooter?
    var serverStatusFooter: SettingsServerSectionFooter? {
        if _serverStatusFooter == nil {
            _serverStatusFooter = self.tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
            _serverStatusFooter?.delegate = self
            _serverStatusFooter?.detailLabel.isHidden = false
        }
        return _serverStatusFooter
    }

    public override func viewDidLoad() {
        // Register a view for section footer
        tableView.registerHeaderFooter(SettingsServerSectionFooter())

        // Listen to textfield change
        serverURLTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        // Check component
        assertTableViewAttached()

        // set placeholder with default value. see SettinForm: initFormData
        serverURLTextField.placeholder = URL.qmobileURLLocalhost.absoluteString
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        foreground {
            self.serverStatusFooter?.checkStatus()
        }
    }

    func textFieldDidChange(textField: UITextField) {
        Prephirences.serverURL = textField.text

        serverStatusFooter?.checkStatus(2)
    }

    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let section = Section(rawValue: section), case .server = section {
            return serverStatusFooter
        }
        return nil
    }

    var position: Int?
}

extension SettingURLForm: SettingsServerSectionFooterDelegate {

    public func statusChanged(status: ServerStatus) {
        if case .checking = status {
            position = self.serverURLTextField.cursorPosition
        }
        logger.verbose("caret position \(String(describing: position))")

        self.reload(section: Section.server)

        self.serverURLTextField.cursorPosition = position
        self.serverURLTextField.becomeFirstResponder()
        self.serverURLTextField.cursorPosition = position
    }

}
