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

private let kHeaderContext = "X-QMobile-Context"

class ActionWebAreaController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {

    var urlString: String!
    var action: Action!
    // var actionUI: ActionUI
    var context: ActionContext!

    fileprivate var activityIndicator: ActivityIndicator?
    fileprivate var tapOutsideRecognizer: UITapGestureRecognizer!
    var webView: WKWebView?
    fileprivate var reloadDialog: DialogForm?

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
                let url = components.url
                logger.debug("ActionWebAreaControler url is \(String(describing: url))")
                return url
            }
        } else if !urlString.hasPrefix("http") {
            logger.debug("ActionWebAreaControler url is https://\(urlString)")
            return URL(string: "https://"+urlString)
        } else {
            return URL(string: urlString)
        }

        return nil
    }()

    lazy var headerFields: [String: String]? = {
        if let actionContext = context.actionContextParameters() {
            guard let data = try? JSONSerialization.data(withJSONObject: actionContext, options: []) else {
                logger.warning("Failed to encode context for web are \(actionContext)")
                return nil
            }
            logger.debug("headerFields is \(data.base64EncodedString())")
            return [kHeaderContext: data.base64EncodedString()]
        }
        return nil
    }()

    func loadURL() {
        logger.debug("loadURL \(String(describing: action.url))")
        webView?.configuration.websiteDataStore.httpCookieStore.injectSharedCookies()
        if let url = self.url {
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = self.headerFields
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
        self.initReloadUI()
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
        case .cannotFindHost, .cannotConnectToHost: // -1004
            logger.warning("Not available.")
        case .notConnectedToInternet, .dataNotAllowed:
            logger.warning("No network.\nPlease check wifi or mobile data and try again.")
        case .fileDoesNotExist:
            logger.warning("Trying to load a non existing file.")
        default:
            logger.warning("Unknown error receive \((error as NSError).code).\n \((error as NSError))")
        }
        self.webView?.stopLoading()
        self.activityIndicator?.stopAnimating()
        self.showReloadUI()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (() -> Void)) {

        var layout: MessageView.Layout = .centeredView
        let view = MessageView.viewFromNib(layout: layout)
        view.configureTheme(.info)
        view.configureContent(body: message)
        view.button?.isHidden = false
        view.button?.setTitle("Ok", for: .normal)
        view.iconLabel?.isHidden = true
        view.titleLabel?.isHidden = true
        view.iconImageView?.isHidden = true
        view.tapHandler = SwiftMessages.defaultTapHandler
        view.buttonTapHandler = SwiftMessages.defaultButtonTapHandler

        var config = SwiftMessages.Config()
        config.presentationContext = .viewController(self)
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .gray(interactive: true)
        config.eventListeners.append { event in
            switch event {
            case .willHide:
                break
            case .didHide:
                completionHandler()
            default:
                break
            }
        }
        SwiftMessages.show(config: config, view: view)
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

extension ActionWebAreaController {

    fileprivate func initActivityIndicator() {
        logger.debug("initActivityIndicator \(String(describing: action.url))")
        self.activityIndicator = ActivityIndicatorBar(view: self.view)
    }

    fileprivate func initWebView() {
        logger.debug("initWebView \(String(describing: action.url))")
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
                if let level = messageInfo["level"] as? String {
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
extension ActionWebAreaController {

    func initReloadControl() {
        logger.debug("initReloadControl \(String(describing: action.url))")
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
        logger.debug("uninitReloadControl \(String(describing: action.url))")
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

    func initReloadUI() {
        logger.debug("initReloadUI \(String(describing: action.url))")
        let dialog = DialogForm(nibName: "ReloadWebArea", bundle: Bundle(for: ActionWebAreaController.self))
        dialog.delegate = self
        dialog.cornerRadius = 12
        dialog.dismissOnTap = false
        dialog.modalPosition = .center
        dialog.modalSize = (.threeQuarters, .custom(size: 128))

        self.reloadDialog = dialog
    }

    func showReloadUI() {
        logger.debug("showReloadUI \(String(describing: action.url))")
        self.reloadDialog?.show(self, animated: true) {
            logger.debug("Reload dialog shown")
        }
    }

    func hideReloadUI() {
        logger.debug("hideReloadUI \(String(describing: action.url))")
        self.reloadDialog?.dismissAnimated()
    }

    @IBAction func reload(_ sender: Any) {
        logger.debug("reload \(String(describing: action.url))")
        guard let webView = webView else { return }
        hideReloadUI()
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

// MARK: reload and close using dialog
extension ActionWebAreaController: DialogFormDelegate {

    func onOK(dialog: DialogForm, sender: Any) {
        logger.verbose("try again \(String(describing: action.url))")
        assert(dialog == self.reloadDialog)
        reload(sender)
    }

    func onCancel(dialog: DialogForm, sender: Any) {
        logger.verbose("cancel \(String(describing: action.url))")
        assert(dialog == self.reloadDialog)
        hideReloadUI()
        self.dismissAnimated()
    }
}

// MARK: close with tap gesture
extension ActionWebAreaController: UIGestureRecognizerDelegate {

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
