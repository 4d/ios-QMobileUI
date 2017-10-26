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
import Prephirences
import FileKit

class ApplicationLogger: NSObject {}

let logger = Logger.forClass(ApplicationLogger.self)

extension ApplicationLogger: ApplicationService {

    static var instance: ApplicationService = ApplicationLogger()

    var logPref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "log.")
    }

    // swiftlint:disable:next function_body_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {

        let showThreadName = logPref["showThreadName"] as? Bool ?? true
        let showLevel = logPref["showLevel"] as? Bool ?? true
        let showFileNames = logPref["showFileNames"] as? Bool ?? true
        let showLineNumbers = logPref["showLineNumbers"] as? Bool ?? true
        let showFunctionName = logPref["showFunctionName"] as? Bool ?? true
        let showDate = logPref["showDate"] as? Bool ?? true
        let showLogIdentifier = logPref["showLogIdentifier"] as? Bool ?? false
        let writeToFile = logPref["writeToFile"] as? String
        let directory = logPref["directory"] as? String ?? "logs"
        let autorotate = logPref["autorotate"] as? Bool ?? true
        let maxFileSize = logPref["maxFileSize"] as? UInt64
        let maxLogFiles = logPref["maxLogFiles"] as? UInt8

        let levelPref: Preference<XCGLogger.Level> = logPref.preference(forKey: "level")
        levelPref.transformation = XCGLogger.Level.preferenceTransformation
        #if DEBUG
            let level: XCGLogger.Level = levelPref.value ?? .verbose
        #else
            let level: XCGLogger.Level = levelPref.value ?? .info
        #endif

        let fileLevelPref: Preference<XCGLogger.Level> = logPref.preference(forKey: "fileLevel")
        fileLevelPref.transformation = XCGLogger.Level.preferenceTransformation
        #if DEBUG
            let fileLevel: XCGLogger.Level? = fileLevelPref.value
        #else
            let fileLevel: XCGLogger.Level? = fileLevelPref.value
        #endif

        let formatterPref: Preference<LogFormatter> = logPref.preference(forKey: "formatter")
        formatterPref.transformation = LogFormatter.preferenceTransformation
        #if DEBUG
            let formatter: LogFormatter? = formatterPref.value ?? LogFormatter.emoticon
        #else
            let formatter: LogFormatter? = formatterPref.value
        #endif

        logger.outputLevel = level

        if let destination = logger.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
            destination.showLogIdentifier = showLogIdentifier
            destination.showFunctionName = showFunctionName
            destination.showThreadName = showThreadName
            destination.showLevel = showLevel
            destination.showFileName = showFileNames
            destination.showLineNumber = showLineNumbers
            destination.showDate = showDate
            destination.outputLevel = level

            if let formatter = formatter {
                destination.formatters = [formatter.formatter]
            }
            #if DEBUG
                // immediate
            #else
                destination.logQueue = XCGLogger.logQueue
            #endif
        }

        if let writeToFile = writeToFile, let writeURL = logDirectory(directory)?.appendingPathComponent(writeToFile) {

            let destination: FileDestination
            if !autorotate {
                destination = FileDestination(writeToFile: writeURL, identifier: XCGLogger.Constants.fileDestinationIdentifier)
            } else {
                let autodestination = AutoRotatingFileDestination(writeToFile: writeURL, identifier: XCGLogger.Constants.fileDestinationIdentifier, shouldAppend: true, appendMarker: nil, archiveSuffixDateFormatter: nil)

                if let maxFileSize = maxFileSize {
                    autodestination.targetMaxFileSize = maxFileSize
                }
                if let maxLogFiles = maxLogFiles {
                    autodestination.targetMaxLogFiles = maxLogFiles
                }
                autodestination.autoRotationCompletion = { _ in
                     #if DEBUG
                    print("Log autorotation")
                     #endif
                }
                destination = autodestination

                autodestination.cleanUpLogFiles() // XXX maybe do it in task
            }
            destination.showLogIdentifier = showLogIdentifier
            destination.showFunctionName = showFunctionName
            destination.showThreadName = showThreadName
            destination.showLevel = showLevel
            destination.showFileName = showFileNames
            destination.showLineNumber = showLineNumbers
            destination.showDate = showDate
            destination.outputLevel = fileLevel ?? level
            destination.logQueue = XCGLogger.logQueue

            destination.formatters = [LogFormatter.ansi.formatter]

            logger.add(destination: destination)
        }

        logger.logAppDetails()
    }

    func logDirectory(_ directory: String?) -> URL? {
        if let directory = directory, !directory.isEmpty {
            let path = Path.userCaches + directory
            if !path.exists {
                try? path.createDirectory()
            }
            return path.url
        } else {
            return Path.userCaches.url
        }
    }

    enum LogFormatter: String {
        case emoticon
        case ansi

        var formatter: LogFormatterProtocol {
            switch self {
            case .emoticon:
                let prePostFixLogFormatter = PrePostFixLogFormatter()
                prePostFixLogFormatter.apply(prefix: "🗯🗯🗯", postfix: "", to: .verbose)
                prePostFixLogFormatter.apply(prefix: "🔹🔹🔹", postfix: "", to: .debug)
                prePostFixLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️", postfix: "", to: .info)
                prePostFixLogFormatter.apply(prefix: "⚠️⚠️⚠️", postfix: "", to: .warning)
                prePostFixLogFormatter.apply(prefix: "‼️‼️‼️", postfix: "", to: .error)
                prePostFixLogFormatter.apply(prefix: "💣💣💣", postfix: "", to: .severe)
                return prePostFixLogFormatter
            case .ansi:
                let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
                ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
                ansiColorLogFormatter.colorize(level: .debug, with: .black)
                ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
                ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
                ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
                ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
                return ansiColorLogFormatter
            }
        }
    }

}
