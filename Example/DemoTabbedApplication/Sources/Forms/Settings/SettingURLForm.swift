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
    var position: Int?

    // MARK: events

    public override func viewDidLoad() {
        // Register a view for section footer
        initHeaderFooter()

        // Listen to textfield change
        serverURLTextField.addTarget(self, action: #selector(onDataChanged(textField:)), for: .editingChanged)

        // set placeholder with default value. see SettinForm: initFormData
        serverURLTextField.placeholder = URL.qmobileURLLocalhost.absoluteString
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkStatus()
    }

    func onDataChanged(textField: UITextField) {
        Prephirences.serverURL = textField.text
        checkStatus()
    }

    // MARK: table section header and footer
    private func initHeaderFooter() {
        tableView.registerHeaderFooter(SettingsServerSectionFooter())
    }
    private var _serverStatusFooter: SettingsServerSectionFooter?
    var serverStatusFooter: SettingsServerSectionFooter? {
        if _serverStatusFooter == nil {
            _serverStatusFooter = self.tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
            _serverStatusFooter?.delegate = self
            _serverStatusFooter?.detailLabel.isHidden = false
        }
        return _serverStatusFooter
    }
    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let section = Section(rawValue: section), case .server = section {
            return serverStatusFooter
        }
        return nil
    }

    private func checkStatus() {
        serverStatusFooter?.checkStatus(2)
    }

}

extension SettingURLForm: SettingsServerSectionFooterDelegate {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            if case .checking = status {
                self.position = self.serverURLTextField.cursorPosition
            }
            logger.verbose("caret position \(String(describing: self.position))")

           // self.reload(section: Section.server)

            self.forceUpdates()

            self.serverURLTextField.cursorPosition = self.position
            self.serverURLTextField.becomeFirstResponder()
            self.serverURLTextField.cursorPosition = self.position

        }
    }

}
