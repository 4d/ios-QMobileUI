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

@IBDesignable
open class SettingsForm: UITableViewController {

    public enum Section: Int {

        case server
        case account

        public static let all: [Section] = [.server, .account]

        static func register(in tableView: UITableView) {
            for section in Section.all {
                section.register(in: tableView)
            }
        }

        public func register(in tableView: UITableView) {
            switch self {
            case .server:
                tableView.registerHeaderFooter(SettingsServerSectionFooter())
            default:
                break
            }
        }

        public func dequeueFooter(in tableView: UITableView) -> UITableViewHeaderFooterView? {
            switch self {
            case .server:
                return tableView.dequeueReusableHeaderFooterView(SettingsServerSectionFooter.self)
            default:
                return nil
            }
        }

        public func dequeueHeader(in tableView: UITableView) -> UITableViewHeaderFooterView? {
            switch self {
            default:
                return nil
            }
        }
    }

    @IBInspectable open var sectionHeaderForegroundColor: UIColor = /*UIColor(named: "BackgroundColor") ??*/ .clear

    // MARK: event

    final public override func viewDidLoad() {
        super.viewDidLoad()
        initSections() // Register external UI from other file
        initFooter()
        onLoad()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.application(didEnterBackground:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkBackButton()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ServerStatusManager.instance.checkStatus()
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

    // MARK: Manage data data

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dialogForm = segue.destination as? DialogForm,
            let identifier = segue.identifier,
            let button = sender as? UIButton,
            let cell = button.parentCellView as? DialogFormDelegate {
            switch identifier {
            case "confirmReload":
                dialogForm.delegate = cell
            case "confirmLogOut":
                dialogForm.delegate = cell
            default:
                logger.warning("Unknown segue \(identifier) for dialog \(dialogForm)")
            }
        } else {
            logger.debug("UI Transition with segue \(String(describing: segue.identifier))")
        }
    }

    @objc func application(didEnterBackground notification: Notification) {
        // Dismiss all dialog opened in settings if application enter background
        if let dialogForm = self.presentedViewController as? DialogForm {
            onForeground {
                dialogForm.dismiss(animated: false)
            }
        }
    }

    // Footer

    /// Fill footer view with application information
    open func initFooter() {
        if let footerLabel = self.tableView?.tableFooterView as? UILabel {
            if let footerLabelText = Prephirences.sharedInstance["settings.footer.label.text"] as? String {
                footerLabel.text = footerLabelText
            } else {
                footerLabel.text = UIApplication.appName + " (" + UIApplication.appVersion + ")"
            }
        }
        self.tableView?.adjustFooterViewHeightToFillTableView()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView?.adjustFooterViewHeightToFillTableView()
    }

    // init section

    private func initSections() {
        Section.register(in: tableView)
    }

    // MARK: table view

    open override func numberOfSections(in tableView: UITableView) -> Int {
        if Prephirences.Auth.Login.form {
            return Section.all.count
        }
        return Section.all.count - 1
    }

    open override func tableView(_ tableView: UITableView, willDisplay: UITableViewCell, forRowAt: IndexPath) {

    }
    /*open override func tableView(_ tableView: UITableView, heightForRowAt: IndexPath) -> CGFloat {
        return 50
    }*/
    /*open override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }*/
    // - sections

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let sectionEnum = Section(rawValue: section),
            let footer = sectionEnum.dequeueFooter(in: tableView) {
            footer.index = section
            return footer
        }
        return nil
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionEnum = Section(rawValue: section),
            let footer = sectionEnum.dequeueHeader(in: tableView) {
            footer.index = section
            return footer
        }
        return nil
    }

    /*open override func tableView(_ tableView: UITableView, heightForHeaderInSection: Int) -> CGFloat {
        return 48
    }*/
    /*open override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
     }*/
    open override func tableView(_ tableView: UITableView, heightForFooterInSection: Int) -> CGFloat {
        return 48
    }
    /* open override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection: Int) -> CGFloat {
     return 30
     }*/

    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection: Int) {
        if let headerTitle = view as? UITableViewHeaderFooterView,
            sectionHeaderForegroundColor != .clear {
            headerTitle.textLabel?.textColor = sectionHeaderForegroundColor
        }
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView: UIView, forSection: Int) {
    }
}

extension SettingsForm: ServerStatusListener {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            // Reload server status view ie. the footer of server
            self.reload(section: Section.server)
        }
    }
}
