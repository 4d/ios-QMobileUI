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
import DeviceKit
import QMobileAPI

// Service to manage application crash and send report.
class ApplicationCrashManager: NSObject {

    var pref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "crash.")
    }

    static var crashDirectory: Path {
        return Path.userCaches
    }

}

extension ApplicationCrashManager: ApplicationService {

    static var instance: ApplicationService = ApplicationCrashManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard pref["manage"] as? Bool ?? true else { // manage by default
            return
        }

        // Register to crash
        if pref[CrashType.nsexception.rawValue] as? Bool ?? true {
            ApplicationCrashManager.checkDirectory(.nsexception)
            NSSetUncaughtExceptionHandler(nsExceptionHandler)
        }

        if pref[CrashType.signal.rawValue] as? Bool ?? true {
            ApplicationCrashManager.checkDirectory(.signal)

            registerSignalHandler()

            if pref["signal.experimental"] as? Bool ?? false {
                signal(SIGHUP, signalHandler)
                signal(SIGINT, signalHandler)
                signal(SIGQUIT, signalHandler)
                signal(SIGFPE, signalHandler)
                signal(SIGPIPE, signalHandler)
            }
        }

        // Try loading the crash report
        if pref["server.url"] != nil { // do nothing if we not define crash server url

            var crashs = ApplicationCrashManager.crashDirectory.children(recursive: true)
            crashs = crashs.filter { !$0.isDirectory }.filter { $0.fileName != ".DS_Store" }
            crashs = crashs.filter { $0.parent.fileName == CrashType.nsexception.rawValue || $0.parent.fileName == CrashType.signal.rawValue }
            if !crashs.isEmpty {
                logger.info("\(crashs.count) crash file found")

                // Ask user about reporting it:
                // swiftlint:disable:next line_length
                let alert = UIAlertController(title: "Oops! It looks like your app didn't close correctly. Want to help us get better?",
                                              message: "An error report has been generated, please send it to 4D.com. We'll keep your information confidential.",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Save report for later", style: UIAlertActionStyle.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Send report", style: UIAlertActionStyle.default, handler: { _ in
                    self.send(crashs: crashs)
                }))
                alert.addAction(UIAlertAction(title: "Don't send a report", style: UIAlertActionStyle.destructive, handler: deleteCrashFile))

                alert.present()
            }
        }
    }

}

// MARK: present dialog
extension UIAlertController {
    fileprivate func present() {
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindowLevelAlert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(self, animated: true, completion: nil)
    }
}

extension ApplicationCrashManager {

    // MARK: Actions
    open func deleteCrashFile(_ action: UIAlertAction) {
        let crashDirectory = ApplicationCrashManager.crashDirectory
        self.deleteCrashFile(pathCrash: crashDirectory, zipPath: crashDirectory)
    }

    fileprivate func send(crashs: [Path]) {
        //clean tmp
        self.deleteCrashFile(pathCrash: Path.userTemporary + "data", zipPath: Path.userTemporary + "data.zip")
        //add log files corresponding to the crash files
        for crash in crashs {
            zipFile(crashFile: crash)
            getLogFromCrach(crashFile: crash)
        }
        //zip folder tmp and send
        zipAndSend(crashFile: Path.userTemporary + "data", crashsFiles: crashs)
    }

    fileprivate func getLogFromCrach(crashFile: Path) {
        var logs = ApplicationCrashManager.crashDirectory.children(recursive: true)
        logs = logs.filter { !$0.isDirectory }.filter { $0.fileName != ".DS_Store" }
        logs = logs.filter { $0.parent.fileName == "logs"  }
        for log in logs {
            if getLog(nameLogFile: log.fileName, nameCrashFile: crashFile.fileName) {
                zipFile(crashFile: log)
            }
        }
    }

    fileprivate func getLog(nameLogFile: String, nameCrashFile: String) -> Bool {
        var nameCrashFileArr = nameCrashFile.components(separatedBy: "-")
        if !nameCrashFileArr.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYYMMdd"
            if let date = dateFormatter.date(from: "\(nameCrashFileArr[0])") {
                dateFormatter.dateFormat = "YYYY-MM-dd"
                if nameLogFile.contains("debug_\(dateFormatter.string(from: (date)))") {
                    return true
                }
            }
        }
        return false
    }

    fileprivate func zipFile(crashFile: Path) {
        let zipPath = self.tempZipPath(fileName: crashFile.fileName, isDirectory: false)
        zipCrashFile(pathCrash: crashFile.absolute, zipPath: zipPath)
    }

    fileprivate func zipAndSend(crashFile: Path, crashsFiles: [Path]) {
        let zipPath = self.tempZipPath(fileName: crashFile.fileName, isDirectory: true)
        if zipCrashFile(pathCrash: crashFile.absolute, zipPath: zipPath) {
            let applicationInformation = ApplicationCrashManager.applicationInformation(fileName: crashFile.fileName)
            send(file: zipPath, parameters: applicationInformation) {
                //delete crash file
                for crash in crashsFiles {
                    self.deleteCrashFile(pathCrash: crash, zipPath: zipPath)
                }
                self.deleteCrashFile(pathCrash: Path.userTemporary + "data", zipPath: Path.userTemporary + "data.zip")
            }
        }
    }

    fileprivate func send(file: Path, parameters: [String: String], onSuccess: @escaping () -> Void) {
        let target = ApplicationServerCrashAPI(fileURL: file.url, parameters: parameters)
        let crashServeProvider = MoyaProvider<ApplicationServerCrashAPI>()
        crashServeProvider.request(target) { (result) in
            switch result {
            case .success(let response):
                do {
                    // You can decode json into struture like `Status`
                    // I submit the code with `Status` but the server must return { "ok": true } if ok
                    // You can have your own object CrashStatus with many information in it, decoded from json
                    let status = try response.map(to: Status.self)
                    if status.ok {
                        onSuccess()
                    } else {
                        logger.warning("Server did not accept the crash file")
                    }
                } catch let error {
                    logger.warning("Failed to decode response from crash server \(error)")
                }
            case .failure(let error):
                logger.warning("Failed to send crash file \(error)")
            }
        }
    }

    // MARK: Files

    /// Return the directory for specific crash type.
    fileprivate static func directory(for type: CrashType) -> Path {
        return ApplicationCrashManager.crashDirectory + type.rawValue
    }

    /// Ensure crash directory is created for crash `type`.
    fileprivate static func checkDirectory(_ type: CrashType) {
        let path = directory(for: type)
        if !path.exists {
            try? path.createDirectory()
        }
    }

    /// Save a crash.
    fileprivate static func save(crash: String, ofType type: CrashType) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd-HHmmss"
        if let appName = Bundle.main["CFBundleIdentifier"] as? String {
            let fName = "\(appName)_\(dateFormatter.string(from: Date()))"
            let path = directory(for: type) + fName
            var crashLog = "\r\n information application: "
            for item in applicationInformation(fileName: path.fileName) {
                crashLog += "\r\n \(item.key) : \(item.value)"
            }
            crashLog += "\r\n *** First throw call "+crash
            try? TextFile(path: path).write(crashLog)
        }
    }

    fileprivate func zipCrashFile(pathCrash source: Path, zipPath: Path) -> Bool {
        do {
            try source.zip(to: zipPath)
            return true
        } catch {
            logger.warning("Failed to zip crash file \(error.localizedDescription)")
            return false
        }
    }

    fileprivate func deleteCrashFile(pathCrash: Path, zipPath: Path) {
        do {
            try pathCrash.deleteFile()
        } catch {
            logger.warning("Failed to delete crash file \(error.localizedDescription)")
        }
        do {
            try zipPath.deleteFile()
        } catch {
            logger.warning("Failed to delete zipped crash file\(error.localizedDescription)")
        }
    }

    // MARK: Temporary files

    fileprivate func tempZipPath(fileName: String, isDirectory: Bool, ext: String = "zip") -> Path {
        if !isDirectory {
            let zipFolder = Path.userTemporary + "data"
            if !zipFolder.exists {
                try? zipFolder.createDirectory()
            }
            return Path.userTemporary + "data/\(fileName).\(ext)"
        } else {
            return Path.userTemporary + "\(fileName).\(ext)"
        }
    }

    // MARK: Get application information

    fileprivate static func applicationInformation(fileName: String) -> [String: String] {
        var information = [String: String]()

        let bundle = Bundle.main
        // Application
        information["CFBundleShortVersionString"] =  bundle[.CFBundleShortVersionString] as? String ?? ""
        information["CFBundleIdentifier"] = bundle[.CFBundleIdentifier] as? String ?? ""
        information["CFBundleName"] = bundle[.CFBundleName] as? String ?? ""

        // Team id
        information["AppIdentifierPrefix"] = bundle["AppIdentifierPrefix"] as? String ?? ""

        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy_HH_mm_ss"
        information["SendDate"] = formatter.string(from: Date())

        // File
        information["fileName"] = fileName

        // OS
        information["DTPlatformVersion"] = bundle[.DTPlatformVersion] as? String ?? "" // XXX UIDevice.current.systemVersion ??

        // Device
        let device = Device.current
        let underlying = device.real
        information["device.description"] = underlying.description
        if device.isSimulator {
            information["device.simulator"] = "YES"
        }
        let versions = Bundle.main["4D"] as? [String: String] ?? [:]
        information["build"] = versions["build"]
        information["component"] = versions["component"]
        information["ide"] = versions["ide"]
        information["sdk"] = versions["sdk"]
        return information
    }

}

// MARK: Crash management

/// Type of crash
enum CrashType: String {
    case nsexception
    case signal
}

public func unSetUncaughtException() {
    NSSetUncaughtExceptionHandler(nil)
}

public func registerSignalHandler() {
    signal(SIGABRT, signalHandler)
    signal(SIGSEGV, signalHandler)
    signal(SIGBUS, signalHandler)
    signal(SIGTRAP, signalHandler)
    signal(SIGILL, signalHandler)
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
