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
import ZIPFoundation

class ApplicationLogger: NSObject {}

let logger = Logger.forClass(ApplicationLogger.self)

extension ApplicationLogger: ApplicationService {

    static var instance: ApplicationService = ApplicationLogger()

    static var logPref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "log.")
    }

    // swiftlint:disable:next function_body_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let logPref = ApplicationLogger.logPref
        let showThreadName = logPref["showThreadName"] as? Bool ?? true
        let showLevel = logPref["showLevel"] as? Bool ?? true
        let showFileNames = logPref["showFileNames"] as? Bool ?? true
        let showLineNumbers = logPref["showLineNumbers"] as? Bool ?? true
        let showFunctionName = logPref["showFunctionName"] as? Bool ?? true
        let showDate = logPref["showDate"] as? Bool ?? true
        let showLogIdentifier = logPref["showLogIdentifier"] as? Bool ?? false
        let autorotate = logPref["autorotate"] as? Bool ?? true
        let maxFileSize = logPref["maxFileSize"] as? UInt64
        let maxLogFiles = logPref["maxLogFiles"] as? UInt8
        let maxTimeInterval = logPref["maxTimeInterval"] as? TimeInterval
        let appleSystem = logPref["appleSystem"] as? Bool ?? false
        let immediate = logPref["immediate"] as? Bool ?? false // if true, debug is easiest, but app perf will discrease

        let levelPref: Preference<XCGLogger.Level> = logPref.preference(forKey: "level")
        levelPref.transformation = XCGLogger.Level.preferenceTransformation
        #if DEBUG
            let level: XCGLogger.Level = levelPref.value ?? .verbose
        #else
            let level: XCGLogger.Level = levelPref.value ?? .info
        #endif

        let fileLevelPref: Preference<XCGLogger.Level> = logPref.preference(forKey: "fileLevel")
        fileLevelPref.transformation = XCGLogger.Level.preferenceTransformation
        let fileLevel: XCGLogger.Level? = fileLevelPref.value

        let formatterPref: Preference<LogFormatter> = logPref.preference(forKey: "formatter")
        formatterPref.transformation = LogFormatter.preferenceTransformation
        #if DEBUG
            let formatter: LogFormatter? = formatterPref.value ?? LogFormatter.emoticon
        #else
            let formatter: LogFormatter? = formatterPref.value
        #endif

        logger.outputLevel = level

        // MARK: output log
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
            if !immediate {
                destination.logQueue = XCGLogger.logQueue
            }
        }

        // MARK: File destination
        let writeURL = ApplicationLogger.currentLog.url
        print("Log will be written into file '\(writeURL)'")
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
            if let maxTimeInterval = maxTimeInterval {
                autodestination.targetMaxTimeInterval = maxTimeInterval
            }
            autodestination.autoRotationCompletion = { success in
                if success {
                    print("Log has been autorotated")
                    self.logAppDetails()
                } else {
                    print("Log has failed to autorotate")
                }
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
        if !immediate {
            destination.logQueue = XCGLogger.logQueue
        }

        destination.formatters = [LogFormatter.ansi.formatter]

        logger.add(destination: destination)

        // MARK: appleSystem destination
        if appleSystem {
            logger.add(destination: AppleSystemLogDestination())
        }

        // MARK: end
        logAppDetails()

        //let dst: Path = Path.userCaches + "test.zip"
        // ApplicationLogger.compressAllLog(to: dst)
    }

    // MARK: Functions
    fileprivate static func logDirectory(_ directory: String?) -> Path {
        if let directory = directory, !directory.isEmpty {
            let path = Path.userCaches + directory
            if !path.exists {
                try? path.createDirectory()
            }
            return path
        } else {
            return Path.userCaches
        }
    }

    static open var currentLog: Path {
        return ApplicationLogger.logDirectory + ApplicationLogger.logFilename
    }
    static open var logDirectory: Path {
        return logDirectory(logPref["directory"] as? String ?? "logs")
    }

    static open var logFilename: String {
        return logPref["writeToFile"] as? String ?? "debug.log"
    }

    static open func logFiles(includeCurrent: Bool = true, rangeDate: Range<Date>? = nil) -> [Path] {
        let currentLog = ApplicationLogger.currentLog
        let pathExtension = currentLog.pathExtension
        let prefix = currentLog.nameWithoutExtension

        var logs = ApplicationLogger.logDirectory.children()
        logs = logs.filter { $0.pathExtension == pathExtension } // only logs
        logs = logs.filter { $0.fileName.starts(with: prefix) } // only with same prefix ex: debug
        if !includeCurrent {
             logs = logs.filter { $0.fileName != currentLog.fileName } // exclude current
        }
        if let rangeDate = rangeDate {
            logs = logs.filter {
                guard let date = $0.modificationDate ?? $0.creationDate else {
                    return false
                }
                return rangeDate.contains(date) // date in specific range
            }
        }
        return logs
    }

    open func logAppDetails() {
        logger.logAppDetails()
        logger.info("IDE \(Bundle.main["4D"] ?? [:])")
    }

    // MARK: custom formatter
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

    // MARK: Compress

    static func compressAllLog(to dst: Path) {
        let logFileste = logFiles()
        do {
            _ = try logFileste.zip(to: dst, compressionMethod: .deflate)
        } catch {
            logger.warning("Failed to zip \(error)")
        }
    }

}

extension Path {
    public var nameWithoutExtension: String {
        return (fileName as NSString).deletingPathExtension
    }
}
