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
open class OpenURLForm: ActionWebAreaController {

    public var reloadButton: LoadingButton!

    open override func viewDidLoad() {
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
        }
        super.viewDidLoad() // will launch all webview creation and URL loading
        webView?.allowsBackForwardNavigationGestures = true

        applyScrollEdgeAppareance()
    }

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
    }

    @IBAction func reloadAnimated(_ sender: Any) {
        reloadButton.isEnabled = false
        reloadButton.startAnimation()
        foreground {
            self.reload(sender)
        }
    }

    open override func onNavigationEnd() {
        guard let button = self.reloadButton else {
            return
        }
        DispatchQueue.main.after(2) {
            button.isEnabled = true
            button.stopAnimation()
        }
    }

    @objc
    open override func showReloadUI() {
        logger.debug("showReloadUI \(String(describing: action.url))")
        self.reloadButton?.isHidden = false
    }

    @objc
    open override func hideReloadUI() {
        self.reloadButton?.isHidden = true
    }

}
