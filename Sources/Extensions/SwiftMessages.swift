//
//  SwiftMessages.swift
//  QMobileUI
//
//  Created by Eric Marchand on 31/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit
import SwiftMessages
import Prephirences

extension SwiftMessages {

    public static var infoColor = UIColor(named: "MessageInfoBackgroundColor")
    public static var infoForegroundColor = UIColor(named: "MessageInfoForegroundColor")
    public static var infoDuration: TimeInterval = Prephirences.sharedInstance["alert.info.duration"] as? TimeInterval ?? 3

    public static var warningColor = UIColor(named: "MessageWarningBackgroundColor")
    public static var warningForegroundColor = UIColor(named: "MessageWarningForegroundColor")
    public static var warningDuration: TimeInterval = Prephirences.sharedInstance["alert.warning.duration"] as? TimeInterval ?? 5.0

    public static var errorColor = UIColor(named: "MessageErrorBackgroundColor")
    public static var errorForegroundColor = UIColor(named: "MessageErrorForegroundColor")
    public static var errorDuration: TimeInterval = Prephirences.sharedInstance["alert.error.duration"] as? TimeInterval ?? 20.0

    /// Hide message when tap.
    public static var defaultTapHandler: ((_ view: BaseView) -> Void) = { _ in SwiftMessages.hide() }

    public static func debug(_ message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        #if DEBUG
        let enabled = Prephirences.sharedInstance["alert.debug.enabled"] as? Bool ?? true
        guard enabled else { return }
        let debugId = "debug"
        SwiftMessages.hide(id: debugId)
        onForeground {
            var layout: MessageView.Layout = .statusLine
            let lineDelimiterPos = message.firstIndex(of: "\n")
            if lineDelimiterPos != nil {
                layout = .messageView
            }

            let view = MessageView.viewFromNib(layout: layout)
            view.id = debugId

            let potentialError: Bool = message.contains("rror")
            if potentialError, let backgroundColor = errorColor, let foregroundColor = errorForegroundColor {
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: nil)
            } else if let backgroundColor = infoColor, let foregroundColor = infoForegroundColor {
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: nil)
            } else {
                view.configureTheme(potentialError ? .error: .info)
            }
            if let lineDelimiterPos = lineDelimiterPos {
                let title = String(message[..<lineDelimiterPos])
                let body = String(message[message.index(lineDelimiterPos, offsetBy: 1)...])
                view.configureContent(title: title, body: body)
            } else {
                view.configureContent(body: message)
            }
            view.button?.isHidden = true
            view.tapHandler = defaultTapHandler

            var config = SwiftMessages.Config()
            if case .statusLine = layout {
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            } else {
                config.presentationContext = .automatic
            }
            config.presentationStyle = .bottom
            // config.duration = .seconds(seconds: infoDuration)

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
        #endif
    }

    public static func info(_ message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            var layout: MessageView.Layout = .statusLine
            let lineDelimiterPos = message.firstIndex(of: "\n")
            if lineDelimiterPos != nil {
                layout = .messageView
            }
            let view = MessageView.viewFromNib(layout: layout)

            if let backgroundColor = infoColor, let foregroundColor = infoForegroundColor {
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: nil)
            } else {
                view.configureTheme(.success)
            }
            if let lineDelimiterPos = lineDelimiterPos {
                let title = String(message[..<lineDelimiterPos])
                let body = String(message[message.index(lineDelimiterPos, offsetBy: 1)...])
                view.configureContent(title: title, body: body)
            } else {
                view.configureContent(body: message)
            }
            view.button?.isHidden = true
            view.tapHandler = defaultTapHandler

            var config = SwiftMessages.Config()
           /* if case .statusLine = layout {
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            } else {*/
                config.presentationContext = .window(windowLevel: .normal)
           /* }*/
            config.presentationStyle = .top
            config.duration = .seconds(seconds: infoDuration)

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func warning(_ message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            var layout: MessageView.Layout = .statusLine
            let lineDelimiterPos = message.firstIndex(of: "\n")
            if lineDelimiterPos != nil {
                layout = .messageView
            }
            let view = MessageView.viewFromNib(layout: layout)

            if let backgroundColor = warningColor, let foregroundColor = warningForegroundColor {
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: nil)
            } else {
                view.configureTheme(.warning)
            }

            if let lineDelimiterPos = lineDelimiterPos {
                let title = String(message[..<lineDelimiterPos])
                let body = String(message[message.index(lineDelimiterPos, offsetBy: 1)...])
                view.configureContent(title: title, body: body)
            } else {
                view.configureContent(body: message)
            }

            view.button?.isHidden = true
            view.tapHandler = defaultTapHandler

            var config = SwiftMessages.Config()
            config.duration = .seconds(seconds: warningDuration)
           /* if case .statusLine = layout {
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            } else {*/
            config.presentationContext = .window(windowLevel: .normal)
           /* }*/

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func error(error: LocalizedError, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        SwiftMessages.error(title: error.errorDescription ?? "", message: error.failureReason ?? "", configure: configure)
    }

    public static func error(title: String, message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            var layout: MessageView.Layout = .cardView
            if title.isEmpty {
                let lineDelimiterPos = message.firstIndex(of: "\n")
                if lineDelimiterPos == nil {
                    layout = .statusLine
                }
            }

            let view = MessageView.viewFromNib(layout: layout)
            if let backgroundColor = errorColor, let foregroundColor = errorForegroundColor {
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: nil)
            } else {
                view.configureTheme(.error)
            }
            view.configureContent(title: title, body: message)
            view.button?.isHidden = true
            view.tapHandler = defaultTapHandler

            var config = SwiftMessages.Config()
            config.duration = .seconds(seconds: errorDuration)
            config.dimMode = .gray(interactive: true) // ex: .blur(style: .prominent, alpha: 0.5, interactive: true)
            config.presentationStyle = .top

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func modal(_ message: String) {
        onForeground {
            let layout: MessageView.Layout = .centeredView
            let view = MessageView.viewFromNib(layout: layout)
            view.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
            view.backgroundView.layer.cornerRadius = 10

            view.configureTheme(.info)

            view.configureContent(title: "", body: message)

            view.button?.isHidden = true
            view.tapHandler = { _ in }

            var config = SwiftMessages.Config()

            config.presentationStyle = .center
            config.duration = .forever
            config.dimMode = .blur(style: .dark, alpha: 1, interactive: false)
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func loading(_ message: String) {
        onForeground {
            //swiftlint:disable:next force_try
            let view: LoadingView = try! SwiftMessages.viewFromNib()
            view.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
            view.backgroundView.layer.cornerRadius = 10

            view.configureTheme(.info)

            view.configureContent(title: "", body: message)

            view.button?.isHidden = true
            view.tapHandler = { _ in }

            var config = SwiftMessages.Config()

            config.presentationStyle = .center
            config.duration = .forever
            config.dimMode = .gray(interactive: false)
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)

            SwiftMessages.show(config: config, view: view)
        }
    }

}
