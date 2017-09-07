//
//  SettingsViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 28/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileDataSync
import Prephirences
import QMobileAPI

public class SettingsForm: UITableViewController {

    public override func viewDidLoad() {

        let nib = UINib(nibName: "SettingsServerSectionFooter", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "SettingsServerSectionFooter")

        assert(tableView.dataSource === self)
        assert(tableView.delegate === self)

        // URL.qmobileURL
        serverURLTextField.text = Prephirences.sharedInstance["server.url"] as? String ?? "http://127.0.0.1"
        serverURLTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        checkStatus(0)
        refreshLastDate()
    }

    // MARK: Servers status

    @IBOutlet weak var serverURLTextField: UITextField!

    let checkServerStatusQueue = OperationQueue(underlyingQueue: .background)

    func textFieldDidChange(textField: UITextField) {
        print("Text changed")
        checkStatus()
    }

    func checkStatus(_ delay: TimeInterval = 3) {
        reloadButton.isEnabled = false
        guard let text = serverURLTextField.text else {
            serverStatus(.noText)
            return
        }
        guard !text.isEmpty else {
            serverStatus(.noText)
            return
        }
        guard var url = URL(string: text) else {
            serverStatus(.notValidURL)
            return
        }
        if url.scheme == nil { // be kind, add scheme
            url = URL(string: "https://\(text)") ?? url
        }

        if url.host?.isEmpty ?? false {
            serverStatus(.notValidURL)
            return
        }

        guard url.isHttpOrHttps else {
            serverStatus(.notValidURL)
            return
        }
        position = self.serverURLTextField.cursorPosition
        serverStatus(.checking)

        checkServerStatusQueue.cancelAllOperations()

        background(delay) {

            self.checkServerStatusQueue.waitUntilAllOperationsAreFinished()
            self.checkServerStatusQueue.addOperation { [unowned self] in
                let apiManager = APIManager(url: url)
                let checkstatus = apiManager.loadStatus(callbackQueue: .background)
                checkstatus.onSuccess(DispatchQueue.main.context) { _ in

                    var pref = Prephirences.sharedMutableInstance ?? UserDefaults.standard
                    pref["server.url"] = text
                    APIManager.instance = apiManager

                    DataSync.instance.rest = APIManager.instance
                    self.serverStatus(.success)
                    self.reloadButton.isEnabled = true
                }
                checkstatus.onFailure(DispatchQueue.main.context) { error in
                    self.serverStatus(.failure(error))
                }
            }

        }

    }

    enum ServerStatus {
        case noText
        case notValidURL
        case checking
        case success
        case failure(Error)

        var isFinal: Bool {
            switch self {
            case .success, .failure: return true
            default: return false
            }
        }
    }

    var serverStatus: ServerStatus = .success
    var position: Int?

    func serverStatus(_ status: ServerStatus) {
        self.serverStatus = status
       /* UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }

        let offset = self.tableView.contentOffset

        UIView.transition(with: self.tableView, duration:0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
            self.tableView.reloadData()
            self.tableView.contentOffset = offset
        }) { (_) in

         }*/
        if case .checking = status {
            position = self.serverURLTextField.cursorPosition
            print("caret position \(position)")
        }
        self.reload(section: Section.server)

        self.serverURLTextField.cursorPosition = position
        self.serverURLTextField.becomeFirstResponder()

    }

    func footerTapped(_ sender: UITapGestureRecognizer) {
        checkStatus()
    }

    // MARK: Manage data data

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var reloadFooterLabel: UILabel!

    @IBAction public func reloadData(_ sender: Any) {
        _ = dataReload { [unowned self] result in

            switch result {
            case .success:
                print("data reloading")
                self.refreshLastDate()
            case .failure(let error):
                print("data reloading failed \(error)")

                // TODO if network url,

                foreground {
                    self.checkStatus()
                }
            }
        }

    }

    func refreshLastDate() {
        foreground {
            if let date = dataLastSync() {
                let id = DateFormatter.shortDateAndTime.string(from: date)
                self.reloadFooterLabel.text = "   Last update: " + id
            }
            self.reload(section: Section.data)
        }
    }
    // MARK: table view

    enum Section: Int {
        case data
        case server
        case remote
    }

    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let section = Section(rawValue: section) {
            switch section {
            case .server:
                let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "SettingsServerSectionFooter")
                if let footer = cell as? SettingsServerSectionFooter {
                    footer.titleLabel.text = serverStatus.description

                    if !footer.tapInstalled {
                        footer.tapInstalled = true

                        let tapAction = UITapGestureRecognizer(target: self, action: #selector(self.footerTapped(_:)))
                        footer.titleLabel.isUserInteractionEnabled = true
                        footer.titleLabel.addGestureRecognizer(tapAction)
                    }
                }
                return cell
            case .data:
                return reloadFooterLabel
            case .remote:
                return nil
            }
        }
        return nil // default
    }

   /* override public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        //if section == 1 {
            if let templateFooter = view as? UITableViewHeaderFooterView {
                //templateFooter.textLabel?.text = templateFooter.textLabel?.text?.localizedLowercase
            }
        //}
    }*/

  /*  public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.accessoryType = .none
    }*/
}

extension SettingsForm.ServerStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .noText:
            return "Please enter the server URL"
        case .notValidURL:
            return "❌ Please enter a valid URL (https://hostname)"
        case .checking:
            return "Checking server accessibility..."
        case .success:
            return "✅ Online"
        case .failure(let error):
            if let error = error as? LocalizedError, let failureReason = error.failureReason {
                return "❌ \(failureReason)"
            }
            return "❌ Server seems not reachable"
        }
    }
}
