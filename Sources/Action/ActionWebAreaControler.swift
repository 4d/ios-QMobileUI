//
//  ActionWebAreaControler.swift
//  QMobileUI
//
//  Created by emarchand on 01/11/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import WebKit

import QMobileAPI
import SwiftMessages

protocol ActivityIndicator {
    func startAnimating()
    func stopAnimating()
}

class ActivityIndicatorBar: ActivityIndicator {
    var view: UIView
    init(view: UIView) {
        self.view = view
    }
    func startAnimating() {
        LinearProgressBar.showProgressBar(self.view)
    }
    func stopAnimating() {
        LinearProgressBar.removeAllProgressBars(self.view)
    }
}

private let kTagPrefix = "{{"
private let kTagSuffix = "}}"

class ActionWebAreaControler: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {

    var urlString: String!
    var action: Action!
    // var actionUI: ActionUI
    var context: ActionContext!

    fileprivate var activityIndicator: ActivityIndicator?
    fileprivate var tapOutsideRecognizer: UITapGestureRecognizer!
    var webView: WKWebView?
    fileprivate var reloadButton: UIButton?

    var dismissHandler: (() -> Void)?

    // MARK: URL
    lazy var url: URL? = {
        guard var urlString = urlString else { return nil }
        // replace data in url string according to action context, ie. record info or table etc...
        if let actionContext = context.actionContextParameters() {
            let table = actionContext[ActionParametersKey.table] as? String ?? ""
            let primaryKey = (actionContext[ActionParametersKey.record] as? [String: String])?[ActionParametersKey.primaryKey]
            ?? ((actionContext[ActionParametersKey.record] as? [String: Int])?[ActionParametersKey.primaryKey])?.toString()
            ?? ""
            /*let parent = (actionContext[ActionParametersKey.parent] as? [String: Any])?.mapValues { "\($0)" }
            if parent != nil {
            }*/
            urlString = urlString.replacingOccurrences(of: "\(kTagPrefix)dataClass\(kTagSuffix)", with: table)
            urlString = urlString.replacingOccurrences(of: "\(kTagPrefix)entity.primaryKey\(kTagSuffix)", with: primaryKey)
            urlString = urlString.replacingOccurrences(of: "\(kTagPrefix)able\(kTagSuffix)", with: table)
            urlString = urlString.replacingOccurrences(of: "\(kTagPrefix)record\(kTagSuffix)", with: primaryKey)
        }

        if urlString.starts(with: "/") || urlString.starts(with: "\(kTagPrefix)server\(kTagSuffix)") { // append server url
            urlString = urlString.replacingOccurrences(of: "\(kTagPrefix)server\(kTagSuffix)", with: "")
            if var components = URLComponents(url: .qmobile, resolvingAgainstBaseURL: true) { // XXX or APIManager.instance.base.url
                components.path = urlString.hasPrefix("/") ? urlString: "/\(urlString)"
                return components.url
            }
        } else if !urlString.hasPrefix("http") {
            return URL(string: "https://"+urlString)
        } else {
            return URL(string: urlString)
        }

        return nil
    }()

    func loadURL() {
        webView?.configuration.websiteDataStore.httpCookieStore.injectSharedCookies()
        if let url = self.url {
            let request = URLRequest(url: url)
            webView?.load(request)

            LinearProgressBar.removeAllProgressBars(self.view)
            LinearProgressBar.showProgressBar(self.view) // DO not show animated bar in not visible controller, 100%cpu
        } else {
            logger.debug("No valid url to load")
        }
    }

    @IBAction func shareURL(_ sender: Any) {
        if let url = self.url {
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.checkPopUp(sender)

            UIApplication.topViewController?.present(activityViewController, animated: true) {
                logger.info("Share activity presented for url \(url)")
            }
        } else {
            logger.debug("No url to share")
        }
    }

    // MARK: Events
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if webView == nil {
            self.initWebView()
        }
        webView?.frame = view.bounds
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.scrollView.delegate = self

        self.initActivityIndicator()
        self.initReloadControl()
        self.initReloadButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Called when the view has been fully transitioned onto the screen. Default does nothing

        self.initCloseControl()

        // there is no refresh is URL change, you must close this webview and open it again
        foreground {
            self.loadURL()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        uninitCloseControl()
        dismissHandler?()
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.navigationItem.title = webView.title ?? ""
        activityIndicator?.stopAnimating()
        self.uninitReloadControl()
        self.initReloadControl()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator?.stopAnimating()
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator?.startAnimating()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { // open blank link too here
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = URLError.Code(rawValue: (error as NSError).code)
        switch code {
        case .badURL, .unsupportedURL:
            logger.error("Bad url \(String(describing: self.webView?.url))")
            SwiftMessages.error(title: "", message: "Bad URL.\nPlease provide log to app support.", configure: { _, config in return config.viewController(self)})
        case .cannotFindHost, .cannotConnectToHost: // -1004
            SwiftMessages.warning("Not available.", configure: { _, config in return config.viewController(self)})
        case .notConnectedToInternet, .dataNotAllowed:
            SwiftMessages.warning("No network.\nPlease check wifi or mobile data and try again.", configure: { _, config in return config.viewController(self)})
        case .fileDoesNotExist:
            SwiftMessages.warning("Trying to load a non existing file.", configure: { _, config in return config.viewController(self)})
        default:
            SwiftMessages.warning("Unknown error receive \((error as NSError).code).\n \((error as NSError))", configure: { _, config in return config.viewController(self)})
        }
        self.webView?.stopLoading()
        self.activityIndicator?.stopAnimating()
        self.showReloadButton()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (() -> Void)) {
        let alert = UIAlertController(
            title: ""/* frame.request.url?.host */,
            message: message,
            preferredStyle: .alert)
        alert.show()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        manageScriptMessage(message)
    }

}

extension Int {
    fileprivate func toString() -> String {
        return String(self)
    }
}

// MARK: init webview

private let kActionHandler = "mobile"
private let kActionDismiss = "dismiss"
private let kActionStatus = "status"
private let kActionLog = "log"
private let kActionParameterMessage = "message"

extension ActionWebAreaControler {

    fileprivate func initActivityIndicator() {
        self.activityIndicator = ActivityIndicatorBar(view: self.view)
    }

    fileprivate func initWebView() {
        let configuration = WKWebViewConfiguration()
        let script = WKUserScript(source: self.jsScript(), injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
        configuration.userContentController.add(self, name: kActionHandler)

        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        view.addSubview(webView)
        self.webView = webView
    }

    fileprivate func jsScript() -> String {
        return """
var $4d = {
  mobile: {
    \(kActionDismiss): function () {
        window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': '\(kActionDismiss)'});
    },
    \(kActionStatus): function (message) {
        window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': '\(kActionStatus)', '\(kActionParameterMessage)': message});
    },
    action: {
        name: '\(action.name)',
        label: '\(action.preferredLongLabel)',
        shortLabel: '\(action.preferredShortLabel)'
    },
    logger: {
        log: function (level, message) {
            window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': '\(kActionLog)', 'level': level, '\(kActionParameterMessage)': message});
        },
        info: function (message) {
            this.log('info', message);
        },
        debug: function (message) {
            this.log('debug', message);
        },
        warning: function (message) {
            this.log('warning', message);
        },
        error: function (message) {
            this.log('error', message);
        }
    }
  }
};
"""
    }

    @objc fileprivate func manageScriptMessage(_ message: WKScriptMessage) {
        guard message.name == kActionHandler else {
            return // ignore
        }
        guard let body = message.body as? [String: Any], let action = body["action"] as? String else {
            return // ignore
        }
        switch action {
        case kActionDismiss:
            self.dismiss(animated: true) {
                logger.debug("action web view dismissed")
            }
        case kActionStatus:
            if let text = body["message"] as? String {
                SwiftMessages.info(text, configure: { _, config in return config.viewController(self)})
            } else if let messageInfo = body[kActionParameterMessage] as? [String: Any],
                      let text = messageInfo["statusText"] as? String ?? messageInfo[kActionParameterMessage] as? String {
                if let level = body["level"] as? String {
                    switch level {
                    case "debug":
                        SwiftMessages.debug(text, configure: { _, config in return config.viewController(self)})
                    case "info":
                        SwiftMessages.info(text, configure: { _, config in return config.viewController(self)})
                    case "warning":
                        SwiftMessages.warning(text, configure: { _, config in return config.viewController(self)})
                    case "error":
                        SwiftMessages.error(title: "", message: text, configure: { _, config in return config.viewController(self)})
                    default:
                        break
                    }
                } else if messageInfo["success"] as? Bool ?? true {
                    SwiftMessages.info(text, configure: { _, config in return config.viewController(self)})
                } else {
                    SwiftMessages.warning(text, configure: { _, config in return config.viewController(self)})
                }
            }
        case kActionLog:
            if let text = body[kActionParameterMessage] as? String, let level = body["level"] as? String {
                switch level {
                case "verbose":
                    logger.verbose(text)
                case "debug":
                    logger.debug(text)
                case "info":
                    logger.info(text)
                case "warning":
                    logger.warning(text)
                case "error":
                    logger.error(text)
                default:
                    break
                }
            }
        default:
            logger.debug("Unknown message \(message.name )")
        }
    }

}

// MARK: reload with swipe
extension ActionWebAreaControler {

    func initReloadControl() {
        guard let webView = webView else { return }
        if !webView.scrollView.subviews.filter({ $0 is UIRefreshControl}).isEmpty {
            return
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.scrollView.bounces = true
        self.isModalInPresentation = true
    }

    func uninitReloadControl() {
        guard let webView = webView else { return }
        for refresh in webView.scrollView.subviews.compactMap({ $0 as? UIRefreshControl}) {
            refresh.removeFromSuperview()
        }
    }

    @objc
    func refreshWebView(_ sender: UIRefreshControl) {
        self.webView?.reload()
        sender.endRefreshing()
    }

    func initReloadButton() {
        let reloadButton = UIButton()
        reloadButton.backgroundColor = .background
        reloadButton.setTitleColor(.foreground, for: .normal)
        reloadButton.setTitle("Try again", for: .normal)
        reloadButton.isHidden = true

        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        self.webView?.addSubview(reloadButton)
        NSLayoutConstraint.activate([
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reloadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            reloadButton.heightAnchor.constraint(equalToConstant: 50),
            reloadButton.widthAnchor.constraint(equalToConstant: 100)
        ])
        reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        self.reloadButton = reloadButton
    }

    func showReloadButton() {
        self.reloadButton?.isHidden = false
    }

    func hideReloadButton() {
        self.reloadButton?.isHidden = true
    }

    @IBAction func reload(_ sender: Any) {
        guard let webView = webView else { return }
        hideReloadButton()
        if webView.isLoading {
            webView.stopLoading()
        } else {
            if webView.url != nil {
                webView.reload()
            } else {
                loadURL()
            }
        }
    }

}

// MARK: close with tap gesture
extension ActionWebAreaControler: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func initCloseControl() {
        tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapBehind))
        tapOutsideRecognizer.numberOfTapsRequired = 1
        tapOutsideRecognizer.cancelsTouchesInView = false
        tapOutsideRecognizer.delegate = self
        self.view.window?.addGestureRecognizer(tapOutsideRecognizer)
    }

    func uninitCloseControl() {
        if self.tapOutsideRecognizer != nil {
            self.view.window?.removeGestureRecognizer(self.tapOutsideRecognizer)
            self.tapOutsideRecognizer = nil
        }
    }

    @objc
    func handleTapBehind(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            let location: CGPoint = sender.location(in: self.view)
            if !self.view.point(inside: location, with: nil) {
                self.dismissAnimated()
            }
        }
    }
}
