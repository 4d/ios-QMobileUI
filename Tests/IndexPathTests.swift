//
//  IndexPathTests.swift
//  QMobileUI
//
//  Created by Eric Marchand on 12/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileUI

class IndexPathTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFirstRow() {
        var first = IndexPath.firstRow
        XCTAssertEqual(first.row, 0)
        XCTAssertEqual(first.section, 0)
        first.row = 1
        XCTAssertEqual(first.row, 1)

        XCTAssertEqual(IndexPath.firstRow.row, 0)
        
        XCTAssertTrue(IndexPath.firstRow.isFirstSection)
        XCTAssertTrue(IndexPath.firstRow.isFirstRow)
        XCTAssertTrue(IndexPath.firstRow.isFirstRowInSection)
        XCTAssertFalse(IndexPath.firstRow.hasPreviousRowInSection)
        XCTAssertFalse(IndexPath.firstRow.hasPreviousItemInSection)
        XCTAssertFalse(IndexPath.firstRow.hasPreviousRow)
    }

    func testNextPrevious() {
        let row = 50
        var index = IndexPath(row: row, section: 0)
        XCTAssertEqual(index.nextRowInSection.row, row + 1)
        XCTAssertEqual(index.previousRowInSection.row, row - 1)

        index = IndexPath(item: row, section: 0)
        XCTAssertEqual(index.nextItemInSection.item, row + 1)
        XCTAssertEqual(index.previousItemInSection.item, row - 1)
    }

}


