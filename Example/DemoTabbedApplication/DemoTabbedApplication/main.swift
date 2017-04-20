//
//  main.swift
//  Invoices
//
//  Created by Eric Marchand on 19/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileUI

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    NSStringFromClass(QApplication.self),
    NSStringFromClass(AppDelegate.self)
)
