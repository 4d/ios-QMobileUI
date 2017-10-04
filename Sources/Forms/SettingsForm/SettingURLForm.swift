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

open class SettingURLForm: UITableViewController {

    public enum Section: Int {
        case server
    }

    @IBOutlet open weak var serverURLTextField: UITextField!

    // MARK: events
    final public override func viewDidLoad() {
        super.viewDidLoad()
        // Register a view for section footer
        initHeaderFooter()

        // Listen to textfield change
        serverURLTextField.addTarget(self, action: #selector(onDataChanged(textField:)), for: .editingChanged)

        // Set the default value ie. localhost with 4D port
        serverURLTextField.placeholder = URL.qmobileURLLocalhost.absoluteString
        onLoad()
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkStatus()
        onDidAppear(animated)
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onWillDisappear(animated)
    }

    final public override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDidDisappear(animated)
    }

    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default does nothing
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

    open func onDataChanged(textField: UITextField) {
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

    override open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let section = Section(rawValue: section), case .server = section {
            return serverStatusFooter
        }
        return nil // default
    }

    private func checkStatus() {
        serverStatusFooter?.checkStatus(2)
    }

}

extension SettingURLForm: SettingsServerSectionFooterDelegate {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            self.forceUpdates()
        }
    }

}
