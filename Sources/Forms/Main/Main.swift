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
/// then transition to the next controller according to the application state.
open class Main: UIViewController, Form {

    // MARK: event
    final public override func viewDidLoad() {
        super.viewDidLoad()
        setupAppareance()
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

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let loginForm = segue.destination as? LoginForm {
            loginForm.delegate = ApplicationAuthenticate.instance as! ApplicationAuthenticate //swiftlint:disable:this force_cast
        }
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

    // MARK: default behaviour

    /// Use the `Segue` to make the transition, otherwise instanciate hard coded transition.
    open var performSegue = true

    /// By default we do a transition immediately according to application state.
    /// By calling performTransition.
    /// If logged, go to app, else go to login form.
    /// Override this method to deactivate the default transition.
    open func appearTransition() {
        performTransition()
    }

    func setupAppareance() {
        updateStyle()
        switch _style {
        case .light:
            UITabBar.appearance().barStyle = .default
            UINavigationBar.appearance().barStyle = .default
            UISearchBar.appearance().barStyle = .default
        case .dark:
            UITabBar.appearance().barStyle = .black
            UINavigationBar.appearance().barStyle = .blackTranslucent
            UISearchBar.appearance().barStyle = .blackTranslucent

            // UIView.appearance().backgroundColor = UIColor.darkBackground
            // UIColor.darkText
        default:
            break
        }
    }

    @IBInspectable var style: String = "" {
        didSet {
            updateStyle()
        }
    }

    var _style: UserInterfaceStyle = .unspecified //swiftlint:disable:this identifier_name

    func updateStyle() {
        self._style = UserInterfaceStyle(string: style)
    }
}

public extension UIColor {
    // static let darkBackground = UIColor(red: 0.184313725, green: 0.184313725, blue: 0.184313725, alpha: 1.0)

    static let background = UIColor(named: "BackgroundColor")
    static let foreground = UIColor(named: "ForegroundColor")
}

// TODO Use UIUserInterfaceStyle when iOS12
enum UserInterfaceStyle: Int {

    case unspecified

    case light

    case dark

}

extension UserInterfaceStyle {

    init(string: String) {
        switch string {
        case "light": self = .light
        case "dark": self = .dark
        default: self = .unspecified
        }
    }

    var string: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .unspecified: return "unspecified"
        }
    }

}

#if DEBUG
extension UIViewController {
    // /!\ This method use private information
    fileprivate func canPerformSegue(withIdentifier identifier: String) -> Bool {
        guard let segues = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] else { return false }
        return segues.first { $0.value(forKey: "identifier") as? String == identifier } != nil
    }
}
#endif
