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

    func testTimeDateConversion() {
        let timeInterval: TimeInterval = 79200 // 000 / 1000

        //let dateSinceNow = Date(timeIntervalSinceNow: timeInterval)
        //let timeIntervalSinceNow = dateSinceNow.timeIntervalSinceNow
        //XCTAssertEqual(timeInterval, timeIntervalSinceNow) // not possible because time is moving!!!

        let dateSinceReferenceDate = Date(timeIntervalSinceReferenceDate: timeInterval)
        let timeIntervalSinceReferenceDate = dateSinceReferenceDate.timeIntervalSinceReferenceDate
        XCTAssertEqual(timeInterval, timeIntervalSinceReferenceDate)

        let dateSinceSince1970 = Date(timeIntervalSince1970: timeInterval)
        let timeIntervalSince1970 = dateSinceSince1970.timeIntervalSince1970
        XCTAssertEqual(timeInterval, timeIntervalSince1970)

        let date = Date(timeInterval: timeInterval)
        let timeIntervalValue = date.timeInterval
        XCTAssertEqual(timeInterval, timeIntervalValue)
    }

    func testTimeFormatterToString() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = .greenwichMeanTime

        // 4d ?22:00:00?,ds: 79200,rest: 79200000
        XCTAssertEqual(dateFormatter.string(from: Date(timeInterval: 79200)), "10:00 PM")

        XCTAssertEqual(TimeFormatter.simple.string(from: 0), "00:00:00")
        XCTAssertEqual(TimeFormatter.simple.string(from: 79200), "22:00:00")

        XCTAssertEqual(TimeFormatter.medium.string(from: 0), "12:00:00 AM") // en XXX check local?
        XCTAssertEqual(TimeFormatter.medium.string(from: 79200), "10:00:00 PM") // en

        XCTAssertEqual(TimeFormatter.short.string(from: 0), "12:00 AM") // en XXX check local?
        XCTAssertEqual(TimeFormatter.short.string(from: 79200), "10:00 PM") // en

        XCTAssertEqual(TimeFormatter.long.string(from: 0), "12:00:00 AM GMT") // en XXX check local?
        XCTAssertEqual(TimeFormatter.long.string(from: 79200), "10:00:00 PM GMT") // en

        XCTAssertEqual(TimeFormatter.full.string(from: 0), "12:00:00 AM Greenwich Mean Time") // en XXX check local?
        XCTAssertEqual(TimeFormatter.full.string(from: 79200), "10:00:00 PM Greenwich Mean Time") // en
    }

}

extension Date {

    func dateWithoutTime() -> Date {
        let timeZone = TimeZone.current
        let timeIntervalWithTimeZone = self.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86400) * 86400
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }

}
extension TimeInterval{

    func stringFromTimeInterval() -> String {

        let time = NSInteger(self)

        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)

    }
}
