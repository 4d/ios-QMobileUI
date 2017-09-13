//
//  SettingsServerSectionFooter.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 06/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileUI
import QMobileAPI
import QMobileDataSync

import IBAnimatable
import Prephirences
import Moya

public protocol SettingsServerSectionFooterDelegate: NSObjectProtocol {
    func statusChanged(status: ServerStatus)
}

public class SettingsServerSectionFooter: UITableViewHeaderFooterView, UINibable, ReusableView {

    @IBOutlet weak var iconView: AnimatableView!
    @IBOutlet weak var iconAnimationView: AnimatableActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var detailLabel: UILabel!
    weak var delegate: SettingsServerSectionFooterDelegate?

    var serverStatus: ServerStatus = .unknown
    let checkServerStatusQueue = OperationQueue(underlyingQueue: .background)
    
    var cancellables: [Cancellable] = []

    public override func awakeFromNib() {
        super.awakeFromNib()

        // install tap gesture
        let gestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(self.footerTapped(_:)))
        self.iconView.addGestureRecognizer(gestureRecognizer)
        self.titleLabel.addGestureRecognizer(gestureRecognizer)
        self.iconView.isUserInteractionEnabled = true
        self.titleLabel.isUserInteractionEnabled = true

        /*APIManager.reachability { _ in
            self.checkStatus(10)
            }.flatMap { self.cancellables.append($0) }*/
    }
    
    public func update() {
        self.iconView.backgroundColor = serverStatus.color
        self.titleLabel.text = serverStatus.description
        self.detailLabel.text = serverStatus.detailDescription

        foreground {
            if self.serverStatus.isAnimating {
                self.iconAnimationView.startAnimating()
            } else {
                self.iconAnimationView.stopAnimating()
            }
        }
    }

    func footerTapped(_ sender: UITapGestureRecognizer) {
         checkStatus(2)
    }
    func checkStatus(_ delay: TimeInterval = 0) {
        guard let text = Prephirences.sharedInstance["server.url"] as? String, !text.isEmpty else {
            serverStatus(.noText)
            return
        }
        guard var url = URL(string: text) else {
            serverStatus(.notValidURL)
            return
        }

        // Check URL validity
        if url.scheme == nil { // be kind, add scheme
            url = URL(string: "http://\(text)") ?? url
        }
        if url.host?.isEmpty ?? false {
            serverStatus(.notValidURL)
            return
        }
        guard url.isHttpOrHttps else {
            serverStatus(.notValidURL)
            return
        }

        // Start checking
        checkServerStatusQueue.cancelAllOperations()
        checkServerStatusQueue.waitUntilAllOperationsAreFinished()
        background(delay) {
            DispatchQueue.main.sync {
                self.serverStatus(.checking)
            }
            self.checkServerStatusQueue.waitUntilAllOperationsAreFinished()
            self.checkServerStatusQueue.addOperation {
                let apiManager = APIManager(url: url)
                let checkstatus = apiManager.loadStatus(callbackQueue: .background)
                checkstatus.onSuccess(DispatchQueue.main.context) { [weak self] _ in

                    DataSync.instance.rest = APIManager.instance
                    self?.serverStatus(.success)
                }
                checkstatus.onFailure(DispatchQueue.main.context) { [weak self] error in
                    self?.serverStatus(.failure(error))
                }
                /*checkstatus.onComplete { result in
                    apiManager.reachability { _ in
                        self.checkStatus(10)
                        }.flatMap { self.cancellables.append($0) }
                }*/
            }
        }
    }

    private func serverStatus(_ status: ServerStatus) {
        let oldStatus = self.serverStatus
        self.serverStatus = status

        if oldStatus != status {
            delegate?.statusChanged(status: status)
        }

        if case .checking = status {
            //position = self.serverURLTextField.cursorPosition
            //print("caret position \(position)")
        }
        // self.reload(section: Section.server)

        // self.serverURLTextField.cursorPosition = position
        //  self.serverURLTextField.becomeFirstResponder()

    }

}

public class ServerStatusView: AnimatableActivityIndicatorView {

}

// MARK: ServerStatus

public enum ServerStatus {
    case unknown
    case noText
    case notValidURL
    case checking
    case success
    case failure(APIError)
}

extension ServerStatus {

    public var isAnimating: Bool {
        switch self {
        case .checking: return true
        default: return false
        }
    }

    /// It's a final state
    public var isFinal: Bool {
        switch self {
        case .success, .failure: return true
        default: return false
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .success: return true
        default: return false
        }
    }

    public var isFailure: Bool {
        switch self {
        case .failure: return true
        default: return false
        }
    }
}

extension ServerStatus {
    /// A color associated with the server status
    public var color: UIColor {
        switch self {
        case .noText, .notValidURL, .failure:
            return UIColor(red: 244/255, green: 101/255, blue: 96/255, alpha: 1)
        case .checking, .unknown:
            return UIColor.clear
        case .success:
            return UIColor(red: 129/255, green: 209/255, blue: 52/255, alpha: 1)

        }
    }
}

extension ServerStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return ""
        case .noText:
            return "Please enter the server URL"
        case .notValidURL:
            return "Please enter a valid URL (https://hostname)"
        case .checking:
            return "Checking server accessibility..."
        case .success:
            return "Server is online"
        case .failure:
            return "Server is not accessible"
        }
    }

    public var detailDescription: String {
        switch self {
        case .unknown:
            return ""
        case .noText:
            return ""
        case .notValidURL:
            return "P"
        case .checking:
            return ""
        case .success:
            return ""
        case .failure(let error):
            let failureReason = error.failureReason ?? ""
            return "\(failureReason)"
        }
    }
}

extension ServerStatus: Equatable {
    public static func == (left: ServerStatus, rigth: ServerStatus) -> Bool {
        switch (left, rigth) {
        case (.unknown, .unknown): return true
        case (.noText, .noText): return true
        case (.notValidURL, .notValidURL): return true
        case (.checking, .checking): return true
        case (.success, .success): return true
        case (.failure(let error), .failure(let error2)):
            return error.failureReason ==  error2.failureReason
        default: return false
        }
    }
}
