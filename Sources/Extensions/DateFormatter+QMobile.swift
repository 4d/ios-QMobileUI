//
//  DateFormatter+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension DateFormatter {

    static func now(with format: String = "YYYYMMdd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: Date())
    }

    public static let rfc822: DateFormatter = {
        let formatter = DateFormatter()
        // formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    /// Specifies a short style, typically numeric only, such as “11/23/37”.
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Specifies a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    public static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Specifies a long style, typically with full text, such as “November 23, 1937”.
    public static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    /// Specifies a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    public static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    public static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    public static let mediumTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    public static let longTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .long
        return formatter
    }()

    public static let shortDateAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

}

/// Time formatter based on DateFormatter
open class TimeFormatter {

    let dateFormatter = DateFormatter()

    public init(timeStyle: DateFormatter.Style = .short) {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = timeStyle
    }

    open var timeStyle: DateFormatter.Style {
        get {
            return dateFormatter.timeStyle
        }
        set {
             dateFormatter.timeStyle = newValue
        }
    }

    open private(set) var timeFormat: String? {
        get {
            return dateFormatter.dateFormat
        }
        set {
            dateFormatter.dateFormat = newValue
            // do not add `set` without checking if it's a correct time only format
        }
    }

    open func string(from time: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: time)
        return dateFormatter.string(from: date)
    }

    open func string(from integer: Int) -> String {
        let time = TimeInterval(integer)
        return string(from: time)
    }

    open func string(from number: NSNumber) -> String {
        return string(from: TimeInterval(number.doubleValue))
    }

    open func time(from string: String) -> TimeInterval? {
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        return date.timeIntervalSince1970
    }

    open func integer(from string: String) -> Int? {
        guard let time = time(from: string) else {
            return nil
        }
        return Int(time)
    }

    open func number(from string: String) -> NSNumber? {
        guard let time = time(from: string) else {
            return nil
        }
        return NSNumber(value: time)
    }

    /// Specifies a short style, typically numeric only, such as “3:30 PM”.
    public static let short: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Specifies a medium style, typically with abbreviated text, such as “3:30:32 PM”.
    public static let medium: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    /// Specifies a long style, typically with full text, such as “3:30:32 PM PST”.
    public static let long: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .long
        return formatter
    }()

    /// Specifies a full style with complete details, such as “3:30:42 PM Pacific Standard Time”.
    public static let full: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .full
        return formatter
    }()

    /// Specifies a short style, typically numeric only, such as “20:52:55”.
    public static let simple: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeFormat = "HH:mm:ss"
        return formatter
    }()
}
