//
//  NSObject+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public extension NSObject {

    var className: String {
        return type(of: self).className
    }

    static var className: String {
        return stringFromClass(self)
    }

}

public func stringFromClass(_ aClass: AnyClass) -> String {
    return NSStringFromClass(aClass).components(separatedBy: ".").last!
}

public func abstractMethod(function: String = #function, className: String) -> Never {
    fatalError("Internal Error: Function '\(function)' must be implemented on class '\(className)'")
}
