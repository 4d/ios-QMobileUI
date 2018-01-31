//
//  WebAreaForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 31/01/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import WebKit

@IBDesignable
open class WebAreaForm: UIViewController {

    @IBOutlet open var webArea: WKWebView! = nil

    @IBInspectable open var url: String = "http://www.example.com/"
    @IBInspectable open var allowsBackForwardNavigationGestures: Bool = true

    // MARK: view life
    final public override func viewDidLoad() {
        super.viewDidLoad()

        initWebArea()

        self.onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadURL()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    // MARK: specific functions

    // Load the url
    open func loadURL() {
        guard let url = URL(string: url) else { return }
        if url.isFileURL {
            webArea.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            let request = URLRequest(url: url)
            webArea.load(request)
        }
    }

    // Function to setup web area
    open func initWebArea() {
        webArea.navigationDelegate = self
        webArea.uiDelegate = self
        webArea.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
    }

    // MARK: Events

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

    // TODO ADD events for URL loading, see navigation delegate

    // MARK: Web view functions
    @objc public dynamic var isLoading: Bool {
        return self.webArea.isLoading
    }

    @objc public dynamic var estimatedProgress: Double {
        return self.webArea.estimatedProgress
    }

    public func reload() {
        self.webArea.reload()
    }

    public func stopLoading() {
        self.webArea.stopLoading()
    }

    public func evaluateJavaScript(_ javascript: String, completionHandler: ((Any?, Error?) -> Swift.Void)? = nil) {
        self.webArea.evaluateJavaScript(javascript, completionHandler: completionHandler)
    }

    @objc public dynamic var canGoBack: Bool {
        return self.webArea.canGoBack
    }

    @objc public dynamic var canGoForward: Bool {
        return self.webArea.canGoForward
    }

    public func goBack() {
        self.webArea.goBack()
    }

    public func goForward() {
        self.webArea.goForward()
    }

    // MARK: IBAction
    @IBAction public func goBack(_ sender: Any!) {
        self.goBack()
    }

    @IBAction public func goForward(_ sender: Any!) {
        self.goForward()
    }

    @IBAction public func reload(_ sender: Any!) {
        self.reload()
    }

    @IBAction public func stopLoading(_ sender: Any!) {
        self.stopLoading()
    }
}

extension WebAreaForm: WKNavigationDelegate {

}

extension WebAreaForm: WKUIDelegate {

}
