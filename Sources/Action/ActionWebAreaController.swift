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

class ActionWebAreaController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {

    let kActionHandler = "mobile"
    let kTagPrefix = "{{"
    let kTagSuffix = "}}"

    var urlString: String!
    var action: Action?
    // var actionUI: ActionUI
    var context: ActionContext!

    var dismissHandler: (() -> Void)?

    @IBOutlet var webView: WKWebView!
    @IBOutlet weak var reloadButton: UIBarButtonItem!

    // MARK: URL
    lazy var url: URL? = {
        guard var urlString = self.urlString else { return nil }
        // replace data in url string according to action context, ie. record info or table etc...
        if let actionContext = context?.actionContextParameters() {
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
        webView.configuration.websiteDataStore.httpCookieStore.injectSharedCookies()
        if let url = self.url {
            self.reloadButton?.isEnabled = true
            let request = URLRequest(url: url)
            webView.load(request)
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

    @IBAction func reload(_ sender: Any) {
        if self.webView.isLoading {
            self.webView.stopLoading()
        } else {
            self.webView.reload()
        }
    }

    // MARK: Events
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if webView == nil {
            let configuration = WKWebViewConfiguration()
            let scriptSource = """
var $4d = {
  mobile: {
    dismiss: function () {
        window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': 'dismiss'});
    },
    status: function (message) {
        window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': 'status', 'message': message});
    },
    action: {
        name: '\(action?.name ?? "")',
        label: '\(action?.preferredLongLabel ?? "")',
        shortLabel: '\(action?.preferredShortLabel ?? "")'
    },
    logger: {
        log: function (level, message) {
            window.webkit.messageHandlers.\(kActionHandler).postMessage({'action': 'log', 'level': level, 'message': message});
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
            let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(script)
            configuration.userContentController.add(self, name: kActionHandler)

            webView = WKWebView(frame: view.bounds, configuration: configuration)
            view.addSubview(webView)
        }
        webView.frame = view.bounds
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Called when the view has been fully transitioned onto the screen. Default does nothing

        // there is no refresh is URL change, you must close this webview and open it again
        foreground {
            self.loadURL()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissHandler?()
    }
    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        reloadButton?.image = UIImage(systemName: "arrow.clockwise")
        self.navigationItem.title = webView.title ?? ""
        // activityIndicator.stopAnimating()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reloadButton?.image = UIImage(systemName: "arrow.clockwise")
        // activityIndicator.stopAnimating()
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        reloadButton?.image = UIImage(systemName: "xmark")
        // activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { // open blank link too here
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (() -> Void)) {

        let view = MessageView.viewFromNib(layout: .centeredView)
        view.configureTheme(.info)
        view.configureContent(body: message)
        view.tapHandler = SwiftMessages.defaultTapHandler
        view.iconImageView?.isHidden = true
        view.iconLabel?.isHidden = true
        view.titleLabel?.isHidden = true
        view.button?.setTitle("Close", for: .normal)
        view.buttonTapHandler = SwiftMessages.defaultButtonTapHandler

        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: .alert)
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

    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == kActionHandler else {
            return // ignore
        }
        guard let body = message.body as? [String: Any], let action = body["action"] as? String else {
            return // ignore
        }

        switch action {
        case "dismiss":
            self.dismiss(animated: true) {
                logger.debug("action web view dismissed")
            }
        case "status":
            if let text = body["message"] as? String {
                SwiftMessages.info(text, configure: { _, config in return config.viewController(self)})
            } else if let messageInfo = body["message"] as? [String: Any], let text = messageInfo["statusText"] as? String ?? messageInfo["message"] as? String {
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
        case "log":
            if let text = body["message"] as? String, let level = body["level"] as? String {
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

extension Int {
    fileprivate func toString() -> String {
        return String(self)
    }
}
