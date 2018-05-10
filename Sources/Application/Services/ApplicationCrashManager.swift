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
        let alert = UIAlertController(title: "Information", message: "Do you want to send the crash log ?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: UIAlertActionStyle.destructive, handler: { action in
            let crashDirectory = ApplicationCrashManager.crashDirectory
            let crashs = crashDirectory.children(recursive: true).filter { !$0.isDirectory }
            if !crashs.isEmpty {
                for crash in crashs {
                    if let zipPath = self.tempZipPath(fileName: crash.fileName), let pathCrash = self.tempPathFile(parent: crash.parent.fileName) {
                        saveCrashFile(pathCrash: pathCrash+"/"+crash.fileName, zipPath: zipPath)
                        let crashServeProvider = MoyaProvider<ApplicationServerCrashAPI>()
                        crashServeProvider.request(.init(zipFile: URL(string:zipPath)! , param: getInfoApp(fileName:crash.fileName))) { (result) in
                            switch result {
                            case .success(let response):
                                do {
                                    try response.filterSuccessfulStatusCodes()
                                    let data = try response.mapJSON()
                                    if ("\(data)" == "ok"){
                                        deleteCrashFile(pathCrash: pathCrash, zipPath: zipPath)
                                    }
                                } catch let error{
                                    print(error)
                                }
                            case .failure(let error): break
                            print(error)
                            }
                        }
                    }
                }
            }
        }))
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }

    static var crashDirectory: Path {
        return Path.userCaches
    }
    func tempPathFile(parent:String) -> String? {
        let path = Path.userCaches + parent//"nsexception"
        let url = URL(fileURLWithPath: path.rawValue)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        return url.path
    }
    func tempZipPath(fileName:String) -> String? {
        let path = Path.userTemporary + "\(fileName).zip"
        return path.absolute.rawValue
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

func getInfoApp(fileName:String) -> Dictionary<String,String> {
    var myPlist = [String: String]()
    myPlist["CFBundleShortVersionString"] = Bundle.main["CFBundleShortVersionString"] as? String
    myPlist["DTPlatformVersion"] = Bundle.main["DTPlatformVersion"] as? String
    myPlist["CFBundleIdentifier"] = Bundle.main["CFBundleIdentifier"] as? String
    myPlist["CFBundleName"] = Bundle.main["CFBundleName"] as? String
    myPlist["AppIdentifierPrefix"] = Bundle.main["AppIdentifierPrefix"] as? String
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy.HH.mm.ss"
    myPlist["SendDate"] = formatter.string(from: date)
    myPlist["fileName"] = fileName
    return myPlist
}

func saveCrashFile(pathCrash:String,zipPath:String) {
    do {
        let source: Path = Path(rawValue: pathCrash)
        try source.zip(to: Path(rawValue: zipPath))
    }catch {
        print(error.localizedDescription)
    }
}

func deleteCrashFile(pathCrash: String, zipPath: String) {
    do {
        let source: Path = Path(rawValue: pathCrash)
        try source.deleteFile()
    }catch {
        print(error.localizedDescription)
    }
    do {
        let source: Path = Path(rawValue: zipPath)
        try source.deleteFile()
    }catch {
        print(error.localizedDescription)
    }
}
