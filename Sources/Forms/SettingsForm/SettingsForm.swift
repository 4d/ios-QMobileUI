//
//  SettingsViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 28/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import Prephirences
import Moya

import QMobileAPI
import QMobileDataSync

open class SettingsForm: UITableViewController {

    public enum Section: Int {
        case data
        case server
        //case about
    }

    @IBOutlet weak var serverURLLabel: UILabel!

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        initHeaderFooter() // Register external UI from other file
        initFormData()
        initFooterData()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkBackButton()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkStatus()
        onDidAppear(animated)
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

    // MARK: init
    /*weak*/var listener: NSObjectProtocol?

    private func initFormData() {
        let urlString = URL.qmobileURL.absoluteString
        serverURLLabel.text = urlString

        listener = Prephirences.serverURLChanged { serverURL in
            self.serverURLLabel.text = serverURL
        }
    }
    private func initFooterData() {
        refreshLastDate()
    }

    // MARK: Manage data data

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var reloadFooterLabel: UILabel!
    var cancellable = CancellableComposite()

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dialogForm = segue.destination as? DialogForm {
            dialogForm.delegate = self
        }
    }

    func refreshLastDate() {
        foreground {
            if let date = dataLastSync() {
                let id = DateFormatter.shortDateAndTime.string(from: date)
                self.reloadFooterLabel.text = "   Last update: " + id // LOCALIZE
            } else {
                self.reloadFooterLabel.text = ""
            }
            self.reload(section: Section.data)
        }
    }

    @objc func application(didEnterBackground notification: Notification) {
        cancellable.cancel()
        if let dialogForm = self.presentedViewController as? DialogForm {
            onForeground {
                dialogForm.dismiss(animated: false)
            }
        }
    }

    // server status

    private func initHeaderFooter() {
        tableView.registerHeaderFooter(SettingsServerSectionFooter())
    }
    private func checkStatus() {
        serverStatusFooter?.checkStatus(0)
    }
    private var _serverStatusFooter: SettingsServerSectionFooter?
    var serverStatusFooter: SettingsServerSectionFooter? {
        if _serverStatusFooter == nil {
            _serverStatusFooter = self.tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
            _serverStatusFooter?.delegate = self
            _serverStatusFooter?.detailLabel.isHidden = true
        }
        return _serverStatusFooter
    }

    // MARK: table view
    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let section = Section(rawValue: section) {
            switch section {
            case .server:
                return serverStatusFooter
            case .data:
                return reloadFooterLabel
            }
        }
        return nil // default
    }

}

extension SettingsForm: SettingsServerSectionFooterDelegate {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            // Reload server status view ie. the footer of server
            self.reload(section: Section.server)
            // Activate reload button if status is ok
            self.reloadButton.isEnabled = status.isSuccess
        }
    }
}

// MARK: action on dialog button press

extension SettingsForm: DialogFormDelegate {

    // if ok pressed
    public func onOK(dialog: DialogForm, sender: Any) {
        cancellable.cancel()
        cancellable = CancellableComposite()

        background(3) { [weak self] in
            guard let this = self, !this.cancellable.isCancelledUnlocked else {
                return
            }

            let center = NotificationCenter.default
            center.addObserver(this, selector: #selector(this.application(didEnterBackground:)), name: .UIApplicationDidEnterBackground, object: nil)

            let reload = dataReload { [weak self] result in
                if let this = self {
                    center.removeObserver(this)
                }

                switch result {
                case .success:
                    logger.info("data reloaded")
                    self?.refreshLastDate()
                    onForeground {
                        dialog.dismiss(animated: true)
                    }
                case .failure(let error):
                    logger.error("data reloading failed \(error)")

                    onForeground {
                        dialog.dismiss(animated: true)
                        self?.serverStatusFooter?.checkStatus()
                    }
                }
            }
            if let reload = reload {
                self?.cancellable.append(reload)
            }
        }
    }

    // if cancel pressed
    public func onCancel(dialog: DialogForm, sender: Any) {
        cancellable.cancel()
        onForeground {
            dialog.dismiss(animated: true) /// XXX maybe wait cancel
        }
    }
}
