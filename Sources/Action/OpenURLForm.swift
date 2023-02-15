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
    }
}
