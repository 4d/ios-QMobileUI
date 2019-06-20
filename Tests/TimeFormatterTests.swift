//
//  TimeFormatterTest.swift
//  Tests
//
//  Created by Eric Marchand on 20/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//
import XCTest
@testable import QMobileUI

class TimeFormatterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testShort() {

      /*  let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        XCTAssertEqual(dateFormatter.string(from: Date(timeInterval: 30)), "")
        XCTAssertEqual(dateFormatter.string(from: Date(timeInterval: 30 * 1000)), "")

        /* TimeFormatter
        XCTAssertEqual(IndexPath.firstRow.row, 0)
        XCTAssertTrue(IndexPath.firstRow.isFirstSection)*/
        let formatter: TimeFormatter = .short
        XCTAssertEqual(formatter.string(from: 0), "")
        XCTAssertEqual(formatter.string(from: 30 * 1000), "")
        XCTAssertEqual(formatter.string(from: 60 * 1000), "")
        XCTAssertEqual(formatter.string(from: 100 * 1000), "")
        XCTAssertEqual(formatter.string(from: (60*60) * 1000), "")
        XCTAssertEqual(formatter.string(from: (2 * (60*60)) * 1000), "")
        XCTAssertEqual(formatter.string(from: (2 * (60*60) + 50) * 1000), "")*/
    }

}


