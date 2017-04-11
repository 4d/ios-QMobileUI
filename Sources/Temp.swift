//
//  Temp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// A temp file allow fast cocoapod developement allowing to inject code in dev pods when new files must be created

extension UISwipeGestureRecognizerDirection: Hashable {
    public var hashValue: Int {
        return Int(self.rawValue)
    }

    public static let allArray: [UISwipeGestureRecognizerDirection] = [.left, .right, .up, .down]

}
