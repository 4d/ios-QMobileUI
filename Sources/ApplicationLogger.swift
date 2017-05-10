//
//  ApplicationLogger.swift
//  Invoices
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore
import XCGLogger

class ApplicationLogger: NSObject {}

let logger = Logger.forClass(ApplicationLogger.self)

extension ApplicationLogger: ApplicationService {

    static var instance: ApplicationService = ApplicationLogger()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        // TODO configure logging framework here, default level, default destination, etc...
        // Could be done using userdefaults for some basic features

        // logger.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file", fileLevel: .debug)

        // TODO setup all frameworks logger...

        #if DEBUG
            let prePostFixLogFormatter = PrePostFixLogFormatter()
            prePostFixLogFormatter.apply(prefix: "🗯🗯🗯", postfix: "", to: .verbose)
            prePostFixLogFormatter.apply(prefix: "🔹🔹🔹", postfix: "", to: .debug)
            prePostFixLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️", postfix: "", to: .info)
            prePostFixLogFormatter.apply(prefix: "⚠️⚠️⚠️", postfix: "", to: .warning)
            prePostFixLogFormatter.apply(prefix: "‼️‼️‼️", postfix: "", to: .error)
            prePostFixLogFormatter.apply(prefix: "💣💣💣", postfix: "", to: .severe)
            logger.formatters = [prePostFixLogFormatter]

            logger.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, fileLevel: .debug)
        #else
            logger.setup(level: .info, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, fileLevel: .debug)

            // Could write to a files, write in database
            /*if let consoleLog = logger.logDestination(XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
                consoleLog.logQueue = XCGLogger.logQueue
            }*/
        #endif
    }
}
