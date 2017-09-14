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
    weak var serverStatusFooter: SettingsServerSectionFooter?
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
        let key = "server.url"
        serverURLLabel.text = Prephirences.sharedInstance[key] as? String ?? URL.qmobileURLLocalhost.absoluteString

        listener = UserDefaults.standard.observe(forKeyPath: key) { pref, keyModified in
            if keyModified == key {
                self.serverURLLabel.text = pref[key] as? String ?? URL.qmobileURLLocalhost.absoluteString
            }
        }

    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        foreground {
            self.serverStatusFooter?.checkStatus()
        }
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "keyPath")
    }

    private func initFooterData() {
        refreshLastDate()
    }

    // MARK: Manage data data

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var reloadFooterLabel: UILabel!

    @IBAction public func reloadData(_ sender: Any) {

        /*
        _ = dataReload { [unowned self] result in

            switch result {
            case .success:
                loggerapp.info("data reloading")
                self.refreshLastDate()
            case .failure(let error):
                loggerapp.error("data reloading failed \(error)")

                foreground {
                    self.serverStatusFooter?.checkStatus()
                }
            }
        }
*/
        let dialog = AZDialogViewController(title: "Refresh data", message: "")
        dialog.allowDragGesture = true

        var cancellable: Cancellable? = nil

        let action = AZDialogAction(title: "Launch") { dialog in

            dialog.removeAction(at: 0)

            dialog.message = "Updating..."

            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            let container = dialog.container
            dialog.container.addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
            indicator.startAnimating()

            cancellable = dataReload { result in
                foreground {
                    dialog.removeAllActions()

                    switch result {
                    case .success:
                        dialog.message = "Success"
                        loggerapp.debug("success")
                    case .failure(let error):
                       // dialog.message = "Failed to reload data \(error)"

                        print("error \(error)")
                        dialog.dismiss()
                    }


                    let dismissAction = AZDialogAction(title: "Dismiss") { dialog in
                        dialog.dismiss()
                    }
                    dialog.addAction(dismissAction)

                    DispatchQueue.main.after(10) {
                        dialog.dismiss()
                    }
                }
            }

        }
        dialog.addAction(action)

        let cancelAction = AZDialogAction(title: "Cancel") { dialog in

            cancellable?.cancel()

            //add your actions here.
            dialog.dismiss()
        }

        dialog.addAction(cancelAction)

        dialog.show(in: self)

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
                if serverStatusFooter == nil {
                    serverStatusFooter = self.tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
                    serverStatusFooter?.delegate = self
                    serverStatusFooter?.checkStatus()
                    serverStatusFooter?.detailLabel.isHidden = true

                }
                serverStatusFooter?.update()
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
