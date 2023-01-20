//
//  DateFormatter+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

/// property to define locale of formatters
let kFormatterLocal = "formatter.locale"
/// value of `kFormatterLocal` to use use preferred language
let kFormatterLocalPreferred = "preferred"

extension TimeZone {
    static let greenwichMeanTime  = TimeZone(secondsFromGMT: 0)! // swiftlint:disable:this force_cast
}

extension Calendar {
    static let iso8601UTC: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static let iso8601GreenwichMeanTime: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .greenwichMeanTime
        return calendar
    }()
}

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
        formatter.timeZone = .greenwichMeanTime
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    /// Specifies a short style, typically numeric only, such as “11/23/37”.
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    public static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        configureLocal(formatter)
        return formatter
    }()

    /// Configure date locale
    static func configureLocal(_ formatter: DateFormatter) {
        if let locale = preferredLocale {
            formatter.locale = locale
            formatter.timeZone = .greenwichMeanTime
        } // else we use currentLocal
    }

    static var preferredLocale: Locale?  = {
        if let identifier = Prephirences.sharedInstance.string(forKey: "date.locale") ??
            Prephirences.sharedInstance.string(forKey: kFormatterLocal) {
            if identifier == kFormatterLocalPreferred, let identifier = Locale.preferredLanguages.first {
                // iOS 10 behaviour: try to use user language when formatting date
                return Locale(identifier: identifier)
            } else {
                return Locale(identifier: identifier)
            }
        }
        return nil
    }()

    /// Specifies a long style, typically with full text, such as “November 23, 1937”.
    public static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        configureLocal(formatter)
        return formatter
    }()

    /// Specifies a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    public static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        configureLocal(formatter)
        return formatter
    }()

    public static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        configureLocal(formatter)
        return formatter
    }()

    public static let mediumTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        configureLocal(formatter)
        return formatter
    }()

    public static let longTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .long
        configureLocal(formatter)
        return formatter
    }()

    public static let shortDateAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        configureLocal(formatter)
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

    open var locale: Locale {
        get {
            return dateFormatter.locale
        }
        set {
            dateFormatter.locale = newValue
        }
    }

    open func string(from time: TimeInterval) -> String {
        let date = Date(timeInterval: time)
        return dateFormatter.string(from: date)
    }

    open func string(from integer: Int) -> String {
        let time = TimeInterval(integer)
        return string(from: time)
    }

    open func string(from number: NSNumber, milliseconds: Bool = true) -> String {
        let timeInterval = milliseconds ? TimeInterval(number.doubleValue / 1000): TimeInterval(number.doubleValue)
        return string(from: timeInterval)
    }

    open func time(from string: String) -> TimeInterval? {
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        // XXX add one year ?
        return Calendar.current.date(byAdding: .year, value: 1, to: date)?.timeInterval
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

    static func configure(_ formatter: TimeFormatter) {
       /* if let locale = preferredLocale {
            formatter.locale = locale
        } // else we use currentLocal*/
        formatter.dateFormatter.timeZone = .greenwichMeanTime
    }

   /* static var preferredLocale: Locale?  = {
        if let identifier = Prephirences.sharedInstance.string(forKey: "time.locale") ??
            Prephirences.sharedInstance.string(forKey: kFormatterLocal) {
            if identifier == kFormatterLocalPreferred, let identifier = Locale.preferredLanguages.first {
                // iOS 10 behaviour: try to use user language when formatting time
                return Locale(identifier: identifier)
            } else {
                return Locale(identifier: identifier)
            }
        }
        return nil
    }()*/

    /// Specifies a short style, typically numeric only, such as “3:30 PM”.
    public static let short: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .short
        configure(formatter)
        return formatter
    }()

    /// Specifies a medium style, typically with abbreviated text, such as “3:30:32 PM”.
    public static let medium: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .medium
         configure(formatter)
        return formatter
    }()

    /// Specifies a long style, typically with full text, such as “3:30:32 PM PST”.
    public static let long: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .long
         configure(formatter)
        return formatter
    }()

    /// Specifies a full style with complete details, such as “3:30:42 PM Pacific Standard Time”.
    public static let full: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeStyle = .full
         configure(formatter)
        return formatter
    }()

    /// Specifies a short style, typically numeric only, such as “20:52:55”.
    public static let simple: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeFormat = "HH:mm:ss"
        configure(formatter)
        return formatter
    }()

    /// Specifies a short style, typically numeric only, such as “20:52”.
    public static let hourMinute: TimeFormatter = {
        let formatter = TimeFormatter()
        formatter.timeFormat = "HH:mm"
        configure(formatter)
        return formatter
    }()
}
