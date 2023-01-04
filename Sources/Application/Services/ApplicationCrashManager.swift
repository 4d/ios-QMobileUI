//
//  ApplicationCrashManager.swift
//  QMobileUI
//
//  Created by Eric Marchand on 26/10/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import XCGLogger
import Prephirences
import FileKit
import Moya
import QMobileAPI

// Service to manage application crash and send report.
class ApplicationCrashManager: NSObject {
    var pref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "crash.")
    }
    static var pref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "crash.")
    }
    static var parentCrashDirectory: Path {
        return Path.userCaches
    }
    var window: UIWindow?
}

// MARK: Service
extension ApplicationCrashManager: ApplicationService {

    static var instance: ApplicationService = ApplicationCrashManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
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
                registerSignalExperimentalHandler()
            }
        }

        // Try loading the crash report
        if ApplicationCrashManager.isConfigured { // do nothing if we not define crash server url

            let crashs = ApplicationCrashManager.crash()
            if !crashs.isEmpty {
                logger.info("\(crashs.count) crash file found")

                // Ask user about reporting it:
                let alert = UIAlertController(title: "Oops! It looks like your app didn't close correctly. Want to help us get better?",
                                              message: "An error report has been generated, please send it to 4D.com. We'll keep your information confidential.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Save report for later", style: .cancel, handler: { _ in
                    self.window = nil
                }))
                alert.addAction(UIAlertAction(title: "Send report", style: .default, handler: { _ in
                    self.send(crashs: crashs)
                    self.window = nil
                }))
                alert.addAction(UIAlertAction(title: "Don't send a report", style: .destructive, handler: { _ in
                    self.deleteCrashFile()
                    self.window = nil
                }))

                foreground {
                    self.window = alert.presentOnTop()
                }
            }
        }
    }

}

extension ApplicationCrashManager {

    static var isConfigured: Bool {
        return pref["server.url"] != nil
    }

    static func crash() -> [Path] {
        var crashs = ApplicationCrashManager.parentCrashDirectory.children(recursive: true)
        crashs = crashs.filter { !$0.isDirectory }.filter { $0.fileName != ".DS_Store" }
        crashs = crashs.filter { $0.parent.fileName == CrashType.nsexception.rawValue || $0.parent.fileName == CrashType.signal.rawValue }
        // XXX For anass it is better to look for file in this parent CrashType folder directly instead of parentCrashDirectory
        return crashs
    }

    // MARK: Actions
    open func deleteCrashFile() {
        let crashDirectory = ApplicationCrashManager.parentCrashDirectory
        self.deleteCrashFile(pathCrash: crashDirectory, zipPath: crashDirectory)
    }

    func send(crashs: [Path]) {
        let data: Path = .userTemporary + "data"
        // clean tmp
        self.deleteCrashFile(pathCrash: data, zipPath: .userTemporary + "data.zip")
        // add log files corresponding to the crash files
        for crash in crashs where zipFile(crashFile: crash) {
            getLogFromCrach(crashFile: crash)
        }
        // zip folder tmp and send
        zipAndSend(crashFile: data, crashsFiles: crashs)
    }

    fileprivate func getLogFromCrach(crashFile: Path) {
        var logs = ApplicationCrashManager.parentCrashDirectory.children(recursive: true)
        logs = logs.filter { !$0.isDirectory }.filter { $0.fileName != ".DS_Store" }
        logs = logs.filter { $0.parent.fileName == "logs"  }
        for log in logs {
            if getLog(nameLogFile: log.fileName, nameCrashFile: crashFile.fileName) ||
                log.fileName == ApplicationLogger.logFilename /* or current log*/ {
                _ = zipFile(crashFile: log)
            }
        }
    }

    fileprivate func getLog(nameLogFile: String, nameCrashFile: String) -> Bool {
        let nameCrashFileArr = nameCrashFile.components(separatedBy: "-")
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

    fileprivate func zipFile(crashFile: Path) -> Bool {
        let zipPath = self.tempZipPath(fileName: crashFile.fileName, isDirectory: false)
        if !zipPath.exists {
            return zipCrashFile(pathCrash: crashFile.absolute, zipPath: zipPath)
        } else {
            return false
        }
    }

    fileprivate func zipAndSend(crashFile: Path, crashsFiles: [Path]) {
        let zipPath = self.tempZipPath(fileName: crashFile.fileName, isDirectory: true)
        if zipCrashFile(pathCrash: crashFile.absolute, zipPath: zipPath) {
            var applicationInformation = QApplication.applicationInformation

            applicationInformation["fileName"] = crashFile.fileName + ".zip"
            applicationInformation["SendDate"] = DateFormatter.now(with: "dd_MM_yyyy_HH_mm_ss")
            applicationInformation["isCrash"] = "1"
            applicationInformation["type"] = "crash"

            send(file: zipPath, parameters: applicationInformation) { success in
                if success {
                    // delete crash file
                    for crash in crashsFiles {
                        self.deleteCrashFile(pathCrash: crash, zipPath: zipPath)
                    }
                    self.deleteCrashFile(pathCrash: crashFile, zipPath: crashFile + ".zip")
                }
            }
        }
    }

    func send(file: Path, parameters: [String: String], onComplete: @escaping (Bool) -> Void) {
        let target = CrashTarget(fileURL: file.url, parameters: parameters)
        MoyaProvider<CrashTarget>().request(target) { (result) in

            let alert = UIAlertController(title: "Failed to send crash file.", message: "", preferredStyle: .alert)
            switch result {
            case .success(let response):
                do {
                    let status = try response.map(to: CrashStatus.self)
                    if status.ok {
                        onComplete(true)
                        alert.title = "Report sent"
                        /// XXX could take message from server like information about bug id created by decoding to CrashStatus
                        var message = "Thank you for helping us improve this app!"
                        if let ticket = status.ticket {
                            message += "\nPlease keep the reference \(ticket) to follow the report"
                        }
                        alert.message = message
                    } else {
                        logger.warning("Server did not accept the crash file")
                        alert.message = "Server did not accept the crash file"
                        onComplete(false)
                    }
                } catch let error {
                    logger.warning("Failed to decode response from crash server \(error)")
                    alert.message = "Failed to decode response from crash server"
                    onComplete(false)
                }
            case .failure(let error):
                logger.warning("Failed to send crash file \(error) with url \(target.baseURL)\(target.path)")
                if let response = error.responseString {
                    logger.warning("with response \(response)")
                }
                alert.message = "Maybe check your network."
                onComplete(false)
            }
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.window = nil
            }))

            self.window = alert.presentOnTop()
        }
    }

    // MARK: Files

    /// Return the directory for specific crash type.
    fileprivate static func directory(for type: CrashType) -> Path {
        return ApplicationCrashManager.parentCrashDirectory + type.rawValue
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
        let fName = dateFormatter.string(from: Date())
        let path = directory(for: type) + fName
        var crashLog = "\r\n information application: "
        for item in QApplication.applicationInformation {
            crashLog += "\r\n \(item.key) : \(item.value)"
        }
        crashLog += "\r\n *** First throw call "+crash
        try? TextFile(path: path).write(crashLog)
    }

    fileprivate func zipCrashFile(pathCrash source: Path, zipPath: Path) -> Bool {
        do {
            try source.zip(to: zipPath, shouldKeepParent: false)
            return true
        } catch {
            logger.warning("Failed to zip crash file \(error.localizedDescription)")
            return false
        }
    }

    fileprivate func deleteCrashFile(pathCrash: Path, zipPath: Path) {
        do {
            if pathCrash.exists {
                try pathCrash.deleteFile()
            }
        } catch {
            logger.warning("Failed to delete crash file \(error.localizedDescription)")
        }
        do {
            if zipPath.exists {
                try zipPath.deleteFile()
            }
        } catch {
            logger.warning("Failed to delete zipped crash file \(error.localizedDescription)")
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

public func registerSignalExperimentalHandler() {
    signal(SIGHUP, signalHandler)
    signal(SIGINT, signalHandler)
    signal(SIGQUIT, signalHandler)
    signal(SIGFPE, signalHandler)
    signal(SIGPIPE, signalHandler)
}

public func unregisterSignalHandler() {
    signal(SIGINT, SIG_DFL)
    signal(SIGSEGV, SIG_DFL)
    signal(SIGTRAP, SIG_DFL)
    signal(SIGABRT, SIG_DFL)
    signal(SIGILL, SIG_DFL)
}

public func unregisterSignalExperimentalHandler() {
    signal(SIGHUP, SIG_DFL)
    signal(SIGINT, SIG_DFL)
    signal(SIGQUIT, SIG_DFL)
    signal(SIGFPE, SIG_DFL)
    signal(SIGPIPE, SIG_DFL)
}

func nsExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason
    let name = exception.name.rawValue
    let userInfo = exception.userInfo

    logger.severe(exception)
    logger.severe(arr)
    logger.severe(reason)

    var crash = "Stack:\n"
    crash = crash.appendingFormat("SlideAdress:0x%0x\r\n", slideAdress())
    crash += "\r\n\r\n name:\(name) \r\n reason:\(String(describing: reason)) \r\n \(arr.joined(separator: "\r\n")) \r\n"
    if let userInfo = userInfo {
        crash += "userInfo: \(userInfo)\r\n"
    }
    crash += "\r\nAdresses: \( Thread.callStackReturnAddresses.map({String(format: "0x%0x", $0.intValue)}).joined(separator: ", ") )\r\n"

    crash += "\r\nBinary:\r\n"
    for (name, slide) in slideAdresses() where slide != 0 {
        crash = crash.appendingFormat("0x%0x", slide)
        crash = crash.appendingFormat(" - %@:", name)
        crash += "\r\n"
    }

    ApplicationCrashManager.save(crash: crash, ofType: .nsexception)
}

func signalHandler(signal: Int32) {
    var crash = "Signal:\(signal)\n"
    crash += "Stack:\n"
    crash = crash.appendingFormat("SlideAdress:0x%0x\r\n", slideAdress())
    for symbol in Thread.callStackSymbols {
        crash = crash.appendingFormat("%@\r\n", symbol)
    }
    crash += "\r\nAdresses: \( Thread.callStackReturnAddresses.map({String(format: "0x%0x", $0.intValue)}).joined(separator: ", ") )\r\n"

    crash += "\r\nBinary:\r\n"
    for (name, slide) in slideAdresses() where slide != 0 {
        crash = crash.appendingFormat("0x%0x", slide)
        crash = crash.appendingFormat(" - %@:", name)
        crash += "\r\n"
    }

    ApplicationCrashManager.save(crash: crash, ofType: .signal)
    exit(signal)
}

import MachO

func slideAdress() -> Int64 {
    var slide: Int64 = 0
    for imageIndex in 0..<_dyld_image_count() {
        let header = _dyld_get_image_header(imageIndex).pointee
        if header.filetype == MH_EXECUTE {
            slide = Int64(_dyld_get_image_vmaddr_slide(imageIndex))
            break
        }
    }
     return slide
}

func slideAdresses() -> [String: Int64] {
    var slides: [String: Int64] = [:]
    for imageIndex in 0..<_dyld_image_count() {
        if /*let header = _dyld_get_image_header(i),*/ let imageNamePtr = _dyld_get_image_name(imageIndex) {
            let imageName = String(cString: imageNamePtr)
           /* switch Int32(header.pointee.filetype) {
            case MH_EXECUTE:*/
                slides[imageName] = Int64(_dyld_get_image_vmaddr_slide(imageIndex))
            /*case MH_DYLIB:
                slides[imageName] = Int64(_dyld_get_image_vmaddr_slide(i))
            default:
                slides[imageName] = Int64(_dyld_get_image_vmaddr_slide(i))
                break
            }*/
        }
    }
    return slides
}
