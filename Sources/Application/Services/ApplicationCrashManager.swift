//
//  ApplicationCrashManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 26/10/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import Foundation
import XCGLogger
import Prephirences
import FileKit

class ApplicationCrashManager: NSObject {}

enum CrashType: String {
    case nsexception
    case signal
}

extension ApplicationCrashManager: ApplicationService {

    static var instance: ApplicationService = ApplicationCrashManager()

    var pref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "crash.")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let crashDirectory = ApplicationCrashManager.crashDirectory
        // Register
        if pref[CrashType.nsexception.rawValue] as? Bool ?? true {
            NSSetUncaughtExceptionHandler(nsExceptionHandler)

            let path = crashDirectory + CrashType.nsexception.rawValue
            if !path.exists {
                try? path.createDirectory()
            }
        }

        if pref[CrashType.signal.rawValue] as? Bool ?? true {
            signal(SIGABRT, signalHandler)
            signal(SIGSEGV, signalHandler)
            signal(SIGBUS, signalHandler)
            signal(SIGTRAP, signalHandler)
            signal(SIGILL, signalHandler)

            if pref["signal.experimental"] as? Bool ?? false {
                signal(SIGHUP, signalHandler)
                signal(SIGINT, signalHandler)
                signal(SIGQUIT, signalHandler)
                signal(SIGFPE, signalHandler)
                signal(SIGPIPE, signalHandler)
            }
            let path = crashDirectory + CrashType.signal.rawValue
            if !path.exists {
                try? path.createDirectory()
            }
        }

        // Maybe at start

        // Try loading the crash report
        let crashs = crashDirectory.children(recursive: true).filter { !$0.isDirectory }
        if !crashs.isEmpty {
            // - read it and make action like asking to send it

            for crash in crashs {
                logger.warning("Crashed on \(crash.creationDate?.description ?? crash.fileName)")
                //logger.warning("Crashed with signal )") // add some info
            }

            // Purge the report = remove all files
            logger.debug("Purge crash file")
            for crash in crashs {
                try? crash.deleteFile()
            }
        }
    }

    static var crashDirectory: Path {
        return Path.userCaches
    }

    static func save(crash: String, ofType type: CrashType) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd-HHmmss"
        let path = Path.userCaches + type.rawValue + dateFormatter.string(from: Date())

        try? TextFile(path: path).write(crash, atomically: true)
    }
}

public func unSetUncaughtException() {
    NSSetUncaughtExceptionHandler(nil)
}

public func unregisterSignalHandler() {
    signal(SIGINT, SIG_DFL)
    signal(SIGSEGV, SIG_DFL)
    signal(SIGTRAP, SIG_DFL)
    signal(SIGABRT, SIG_DFL)
    signal(SIGILL, SIG_DFL)
}

func nsExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason
    let name = exception.name.rawValue

    logger.severe(exception)
    logger.severe(arr)
    logger.severe(reason)

    var crash = "Stack:\n"
    crash += "\r\n\r\n name:\(name) \r\n reason:\(String(describing: reason)) \r\n \(arr.joined(separator: "\r\n")) \r\n\r\n"
    ApplicationCrashManager.save(crash: crash, ofType: .nsexception)
}

func signalHandler(signal: Int32) {
    var crash = "Signal:\(signal)\n"
    crash += "Stack:\n"
    for symbol in Thread.callStackSymbols {
        crash = crash.appendingFormat("%@\r\n", symbol)
    }

    ApplicationCrashManager.save(crash: crash, ofType: .signal)
    exit(signal)
}
