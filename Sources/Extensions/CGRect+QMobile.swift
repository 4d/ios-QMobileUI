//
//  CGRect+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import CoreGraphics

public extension CGRect {

    // swiftlint:disable:next identifier_name
    public var x: CGFloat {
        return origin.x
    }

    // swiftlint:disable:next identifier_name
    public var y: CGFloat {
        return origin.y
    }

    // swiftlint:disable:next identifier_name
    public func with(x: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    // swiftlint:disable:next identifier_name
    public func with(y: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func with(width: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func with(height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func with(origin: CGPoint) -> CGRect {
        return CGRect(origin: origin, size: size)
    }

    public func with(size: CGSize) -> CGRect {
        return CGRect(origin: origin, size: size)
    }

	public var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

public extension CGSize {
    public func with(height: CGFloat) -> CGSize {
        return CGSize(width: self.width, height: height)
    }
    public func with(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: self.height)
    }
    public func divide(by divider: CGFloat) -> CGSize {
        return CGSize(width: self.width / divider, height: self.height / divider)
    }
}
