//
//  Main.swift
//  QMobileUI
//
//  Created by Eric Marchand on Wed, 07 Nov 2018 13:57:21 GMT
//  Copyright © 2017 Eric Marchand. All rights reserved.

import UIKit
import Prephirences
import QMobileAPI

/// Main controller. This controller present a view similar to the launchscreen,
/// then transition to the next controller according to application state.
open class Main: UIViewController {

    /// Transition to perform
    var segue: Segue {
        guard Prephirences.Auth.withForm else {
            return .navigation // no login form
        }
        if let token = APIManager.instance.authToken, token.isValidToken {
            return .navigation // direct login
        }
        return .login // need login
    }

    /// We do a transition immediately according to application state.
    /// If logged, go to app, else go to login form.
    public func appearTransition() {
        foreground {
            self.perform(segue: self.segue)
        }
    }

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }

    /// Main view will appear.
    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearTransition()
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

}
