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

    public static var defaultTapHandler: ((_ view: BaseView) -> Void) = { _ in SwiftMessages.hide() }

    public static func info(_ message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            var layout: MessageView.Layout = .statusLine
            let lineDelimiterPos = message.index(of: "\n")
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
            if case .statusLine = layout {
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            } else {
                config.presentationContext = .automatic
            }
            config.presentationStyle = .top
            config.duration = .seconds(seconds: infoDuration)

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func warning(_ message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            var layout: MessageView.Layout = .statusLine
            let lineDelimiterPos = message.index(of: "\n")
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
            if case .statusLine = layout {
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            } else {
                config.presentationContext = .automatic
            }

            config = configure?(view, config) ?? config

            SwiftMessages.show(config: config, view: view)
        }
    }

    public static func error(title: String, message: String, configure: ((_ view: MessageView, _ config: SwiftMessages.Config) -> SwiftMessages.Config)? = nil) {
        onForeground {
            let view = MessageView.viewFromNib(layout: .cardView)
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

}
