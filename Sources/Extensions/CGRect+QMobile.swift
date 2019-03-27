//
//  CGRect+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import CoreGraphics

public extension CGRect {

    var x: CGFloat { // swiftlint:disable:this identifier_name
        return origin.x
    }

    var y: CGFloat { // swiftlint:disable:this identifier_name
        return origin.y
    }

    func with(x: CGFloat) -> CGRect { // swiftlint:disable:this identifier_name
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func with(y: CGFloat) -> CGRect { // swiftlint:disable:this identifier_name
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func with(width: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func with(height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func with(origin: CGPoint) -> CGRect {
        return CGRect(origin: origin, size: size)
    }

    func with(size: CGSize) -> CGRect {
        return CGRect(origin: origin, size: size)
    }

    var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

public extension CGSize {
    func with(height: CGFloat) -> CGSize {
        return CGSize(width: self.width, height: height)
    }
    func with(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: self.height)
    }
    func divide(by divider: CGFloat) -> CGSize {
        return CGSize(width: self.width / divider, height: self.height / divider)
    }
}
