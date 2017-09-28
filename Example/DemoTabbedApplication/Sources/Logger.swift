//
//  Logger.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 18/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import XCGLogger
import XCGLoggerNSLoggerConnector

extension Tag {
    static let demo = Tag("demo")
}

extension Dev {
    static let eric = Dev("eric")
}
/*
extension Domain {
    static let monitor = Domain("monitor")
    static let test = Domain("👷")
}

extension Image {
    static let done = Image(UIImage(named: "LaunchScreen")!)
}*/
/*
public struct Domain: UserInfoTaggingProtocol {

    /// The name of the developer
    public var name: String

    /// Dictionary representation compatible with the userInfo paramater of log messages
    public var dictionary: [String: Any] {
        return [XCGNSLoggerLogDestination.Constants.userInfoKeyDomain: name]
    }

    /// Initialize a Domain object with a name
    public init(_ name: String) {
        self.name = name
    }

    /// Create a Domain object with a name
    public static func name(_ name: String) -> Domain {
        return Domain(name)
    }

}

public struct Image: UserInfoTaggingProtocol {

    /// The name of the developer
    public var name: UIImage

    /// Dictionary representation compatible with the userInfo paramater of log messages
    public var dictionary: [String: Any] {
        return [XCGNSLoggerLogDestination.Constants.userInfoKeyImage: name]
    }

    /// Initialize a Domain object with a name
    public init(_ name: UIImage) {
        self.name = name
    }

    /// Create a Image object with a name
    public static func name(_ name: UIImage) -> Image {
        return Image(name)
    }

}*/

let logger = XCGLogger.forClass(AppDelegate.self)
