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
import QMobileUI

import AZDialogView

public class SettingsForm: UITableViewController {

    enum Section: Int {
        case data
        case server
        //case about
    }

    @IBOutlet weak var serverURLLabel: UILabel!

    private var _serverStatusFooter: SettingsServerSectionFooter?
    var serverStatusFooter: SettingsServerSectionFooter? {
        if _serverStatusFooter == nil {
            _serverStatusFooter = self.tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
            _serverStatusFooter?.delegate = self
            _serverStatusFooter?.detailLabel.isHidden = true
        }
        return _serverStatusFooter
    }

    /*weak*/var listener: NSObjectProtocol?

    // MARK: override
    public override func viewDidLoad() {
        // Register external UI from other file
        tableView.registerHeaderFooter(SettingsServerSectionFooter())

        initFormData()

        initFooterData()

        // Check storyboard is well configured
        assertTableViewAttached()
    }

    private func initFormData() {
        let urlString = URL.qmobileURL?.absoluteString ?? URL.qmobileURLLocalhost.absoluteString
        if Prephirences.serverURL == nil {
            Prephirences.serverURL = urlString
        }
        serverURLLabel.text = urlString

        listener = Prephirences.serverURLChanged { serverURL in
            self.serverURLLabel.text = serverURL ?? URL.qmobileURLLocalhost.absoluteString
        }

    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // checkstatus when displayinh
        foreground {
            self.serverStatusFooter?.checkStatus()
        }
    }

    private func initFooterData() {
        refreshLastDate()
    }

    // MARK: Manage data data

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var reloadFooterLabel: UILabel!
    var reloadWorker: Cancellable?

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dialogForm = segue.destination as? DialogForm {
            dialogForm.delegate = self
        }
    }

    func refreshLastDate() {
        foreground {
            if let date = dataLastSync() {
                let id = DateFormatter.shortDateAndTime.string(from: date)
                self.reloadFooterLabel.text = "   Last update: " + id
            } else {
                self.reloadFooterLabel.text = ""
            }
            self.reload(section: Section.data)
        }
    }
    // MARK: table view
    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
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
    public func statusChanged(status: ServerStatus) {
        self.reload(section: Section.server)

        self.reloadButton.isEnabled = status.isSuccess
    }
}

extension SettingsForm: DialogFormDelegate {
    public func okPressed(dialog: DialogForm, sender: Any) {
        reloadWorker?.cancel()

        background(5) {
            self.reloadWorker = dataReload { [unowned self] result in

                switch result {
                case .success:
                    logger.info("data reloaded")
                    self.refreshLastDate()
                    dialog.dismiss(animated: true)
                case .failure(let error):
                    logger.error("data reloading failed \(error)")
                    dialog.dismiss(animated: true)

                    foreground {
                        self.serverStatusFooter?.checkStatus()
                    }
                }
            }
        }
    }
    public func cancelPressed(dialog: DialogForm, sender: Any, closeDialog: () -> Void) {
        reloadWorker?.cancel()
        closeDialog() /// XXX maybe wait cancel
    }
}
