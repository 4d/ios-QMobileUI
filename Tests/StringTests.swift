//
//  StringTests.swift
//  QMobileUI
//
//  Created by Eric Marchand on 12/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import XCTest
@testable import QMobileUI

class StringTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testViewCased() {
        XCTAssertEqual("camelCase".viewKeyCased, "camelCase")
        XCTAssertEqual("camel Case".viewKeyCased, "camelCase")
        XCTAssertEqual("camel case".viewKeyCased, "camelCase")
        XCTAssertEqual("Camel case".viewKeyCased, "camelCase")
        XCTAssertEqual("Camel Case".viewKeyCased, "camelCase")
        XCTAssertEqual("CamelCase".viewKeyCased, "camelCase")
        
        
        XCTAssertEqual("Short Date".viewKeyCased, "shortDate")
        XCTAssertEqual("Short Date ".viewKeyCased, "shortDate")
        XCTAssertEqual("Short  Date".viewKeyCased, "shortDate")
        XCTAssertEqual("short  Date".viewKeyCased, "shortDate")
    }
    
}
