//
//  OpenURLForm.swift
//  QMobileUI
//
//  Created by emarchand on 14/02/2023.
//  Copyright © 2023 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI

/// A form to open an url defined by the first injected action. This form coulbe added for instance on the tab bar.
open class OpenURLForm: ActionWebAreaController, FixedForm {

    public var originalParent: UIViewController?

    public var scrollView: UIScrollView?
    public var reloadButton: LoadingButton!

    // MARK: - event
    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default transition to next controller.
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

    final public override func viewDidLoad() {
        // get from injected tag: could be list but we need only one action here
        self.action = self.actionSheet?.actions.first
        if action == nil {
            logger.error("No action defined to open url")
            return
        }
        assert(action.preset == .openURL )
        self.urlString = action.url ?? APIManager.instance.base.url.appendingPathComponent("$/action").absoluteString
        self.context = action // no real context

        // reset action button we do not need it
        if self.navigationController?.navigationBar != nil {
            self.navigationItem.title = action.label
            self.navigationItem.setItems(where: .right, items: nil)
            self.changeNavTitleOnPageChange = false
            self.hideReloadUIWwhenReload = false
        }
        super.viewDidLoad() // will launch all webview creation and URL loading
        webView?.allowsBackForwardNavigationGestures = true

        fixNavigationBarColorFromAsset()

        onLoad()
    }

    override open func willMove(toParent parent: UIViewController?) {
        manageMoreNavigationControllerStyle(parent)
        super.willMove(toParent: parent)
    }

    /// Main view will appear.
    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //reloadButton?.setTitle("Reload", for: .normal) // some weird is
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

    // MARK: - reload
    @objc
    open override func initReloadUI() {
        logger.debug("initReloadUI \(String(describing: action.url))")

        reloadButton = LoadingButton()
        reloadButton.backgroundColor = .background
        reloadButton.setTitleColor(.foreground, for: .normal)
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.setTitle("Reload", for: .selected)
        reloadButton.setTitle("Reload", for: .highlighted)
        reloadButton.layer.cornerRadius = 5
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.addTarget(self, action: #selector(reloadAnimated(_:)), for: .touchUpInside)
        reloadButton.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 30.0, bottom: 10.0, right: 30.0)
        reloadButton.normalCornerRadius = reloadButton.layer.cornerRadius
        self.view.addSubview(reloadButton)

        reloadButton.center(to: self.view)
        reloadButton.sizeToFit()
        reloadButton.activityIndicatorColor = .foreground // set color only after size, to let fit view
        reloadButton.isHidden = true
    }

    @IBAction func reloadAnimated(_ sender: Any) {
        if self.webView?.url != nil {
            return
        }
        reloadButton.startAnimation()
        reloadButton.isEnabled = false
        foreground {
            self.reload(sender)
        }
    }

    open override func onNavigationEnd() {
        guard let button = self.reloadButton, !button.isHidden else {
            return
        }
        DispatchQueue.main.after(2) {
            button.isEnabled = true
            button.stopAnimation()
        }
    }

    @objc
    open override func showReloadUI() {
        logger.debug("showReloadUI \(String(describing: action.url)) \(String(describing: self.webView?.url))")
        if self.webView?.url != nil {
            return
        }
        self.reloadButton?.isHidden = false

    }

    @objc
    open override func hideReloadUI() {
        self.reloadButton?.isHidden = true
    }

}
