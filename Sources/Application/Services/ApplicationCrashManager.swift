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
import Moya

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
        guard pref["manage"] as? Bool ?? true else { // manage by default
            return
        }
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
        if ApplicationServerCrashAPI.crashURL != nil {
            let crashs = crashDirectory.children(recursive: true).filter { !$0.isDirectory }
            if !crashs.isEmpty {
                var crashs = crashDirectory.children(recursive: true)
                crashs = crashs.filter { !$0.isDirectory }
                crashs = crashs.filter { $0.parent.fileName=="nsexception" || $0.parent.fileName == "signal"}
                var dsStory = false
                for crash in crashs {
                    if (crash.parent.fileName=="nsexception" || crash.parent.fileName=="signal") && crash.fileName != ".DS_Store" {
                        dsStory = true
                    }
                }
                if dsStory {
                    // swiftlint:disable:next line_length
                    let alert = UIAlertController(title: "Oops! It looks like your app didn't close correctly. Want to help us get better?", message: "An error report has been generated, please send it to 4D.com. We'll keep your information confidential.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Save report for later", style: UIAlertActionStyle.cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "Send report", style: UIAlertActionStyle.default, handler: { _ in
                        sendReport()
                    }))
                    alert.addAction(UIAlertAction(title: "Don't send a report", style: UIAlertActionStyle.destructive, handler: { _ in
                        notSendReport()
                    }))
                    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
                    alertWindow.rootViewController = UIViewController()
                    alertWindow.windowLevel = UIWindowLevelAlert + 1
                    alertWindow.makeKeyAndVisible()
                    alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    static var crashDirectory: Path {
        return Path.userCaches
    }
    
    func sendReport() {
        let crashDirectory = ApplicationCrashManager.crashDirectory
        let crashs = crashDirectory.children(recursive: true).filter { !$0.isDirectory }
        for crash in crashs {
            if (crash.parent.fileName=="nsexception" || crash.parent.fileName=="signal" || crash.parent.fileName=="logs") && crash.fileName != ".DS_Store" {
                if let zipPath = self.tempZipPath(fileName: crash.fileName), let pathCrash = self.tempPathFile(parent: crash.parent.fileName) {
                    self.saveCrashFile(pathCrash: crash.absolute, zipPath: zipPath)
                    let target = ApplicationServerCrashAPI(fileURL: zipPath.url, parameters: ApplicationCrashManager.applicationInformation(fileName: crash.fileName))
                    let crashServeProvider = MoyaProvider<ApplicationServerCrashAPI>()
                    crashServeProvider.request(target) { (result) in
                        switch result {
                        case .success(let response):
                            do {
                                _ = try response.filterSuccessfulStatusCodes()
                                let data = try response.mapJSON()
                                if "\(data)" == "ok" {
                                    self.deleteCrashFile(pathCrash: crash.absolute, zipPath: zipPath)
                                }
                            } catch let error {
                                logger.warning(error)
                            }
                        case .failure(let error):
                            logger.warning(error)
                        }
                    }
                }
            }
        }
    }
    
    func notSendReport() {
        let crashDirectory = ApplicationCrashManager.crashDirectory
        self.deleteCrashFile(pathCrash: crashDirectory, zipPath: crashDirectory)
    }
    
    func tempPathFile(parent: String) -> Path? {
        let path = Path.userTemporary + parent//"nsexception"
        do {
            try path.createDirectory(withIntermediateDirectories: true)
        } catch {
            return nil
        }
        return path
    }

    func tempZipPath(fileName: String, ext: String = "zip") -> Path? {
        return Path.userTemporary + "\(fileName).\(ext)"
    }

    static func save(crash: String, ofType type: CrashType) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd-HHmmss"
        if let appName = Bundle.main["CFBundleIdentifier"] as? String {
            let fName = "\(appName)_\(dateFormatter.string(from: Date()))"
            let path = Path.userCaches + type.rawValue + fName
            var crashLog = "\r\n information application: "
            for item in applicationInformation(fileName: path.fileName) {
                crashLog += "\r\n \(item.key) : \(item.value)"
            }
            crashLog += "\r\n *** First throw call "+crash
            try? TextFile(path: path).write(crashLog)
        }
    }

    static func applicationInformation(fileName: String) -> [String: String] {
        var information = [String: String]()

        let bundle = Bundle.main
        information["CFBundleShortVersionString"] =  bundle[.CFBundleShortVersionString] as? String
        information["DTPlatformVersion"] = bundle[.DTPlatformVersion] as? String
        information["CFBundleIdentifier"] = bundle[.CFBundleIdentifier] as? String
        information["CFBundleName"] = bundle[.CFBundleName] as? String
        information["AppIdentifierPrefix"] = bundle["AppIdentifierPrefix"] as? String

        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy_HH_mm_ss"
        information["SendDate"] = formatter.string(from: Date())
        information["fileName"] = fileName
        return information
    }

    func saveCrashFile(pathCrash source: Path, zipPath: Path) {
        do {
            try source.zip(to: zipPath)
        } catch {
            logger.warning(error.localizedDescription)
        }
    }

    func deleteCrashFile(pathCrash: Path, zipPath: Path) {
        do {
            try pathCrash.deleteFile()
        } catch {
            logger.warning(error.localizedDescription)
        }
        do {
            try zipPath.deleteFile()
        } catch {
            logger.warning(error.localizedDescription)
        }
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
