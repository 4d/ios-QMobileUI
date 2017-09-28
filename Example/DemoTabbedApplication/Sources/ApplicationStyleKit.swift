//
//  ApplicationStyleKit.swift
//  Invoices
//
//  Created by Eric Marchand on 29/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
//import StyleKit

class ApplicationStyleKit: NSObject {}

extension ApplicationStyleKit: ApplicationService {

    static var instance: ApplicationService = ApplicationStyleKit()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        loadStyles()
    }

    func loadStyles() {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "style.json", subdirectory: nil) {
            for url in urls {
                loadStyle(fileUrl: url)
            }
        }
    }

    func loadStyle(fileUrl: URL) {
       /* #if DEBUG
            let logLevel: SKLogLevel = .debug
        #else
            let logLevel: SKLogLevel = .error
        #endif

        let style = StyleKit(fileUrl: fileUrl, logLevel: logLevel)
        style?.apply()*/
    }

    func inject() {
        loadStyles()
    }

}
