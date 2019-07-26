//
//  NSSetTests.swift
//  Tests
//
//  Created by Eric Marchand on 26/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import XCTest
@testable import QMobileUI

class NSSetTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSet() {
        let set = NSSet(array: ["a", "b", "c"])

        let value = set.value(forKeyPath: "count")
        XCTAssertEqual(value as? Int, set.count)
    }

    func testOrderedSet() {
        let set = NSOrderedSet(array: ["a", "b", "c"])

        let value = set.value(forKeyPath: "count")
        XCTAssertEqual(value as? Int, set.count)

        let value2 = set.value(forKeyPath: "[2]")
        XCTAssertEqual(value2 as? String, set.object(at: 2) as? String)

        XCTAssertNil(set.value(forKeyPath: "[5]"))
    }

}
