//
//  UILabel+Binding.swift
//  Invoices
//
//  Created by Eric Marchand on 31/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileAPI

extension Bundle {
    /// Bundle used to get binded localized value, default .main bundle of your application
     @nonobjc open static var uiBinding: Bundle = .main
}

extension String {

    var localizedBinding: String {
        return NSLocalizedString(self, bundle: .uiBinding, comment: "")
    }

    var localizedFramework: String {
        return NSLocalizedString(self, bundle: Bundle(for: Binder.self), comment: "")
    }

    func localized(with comment: String = "", bundle: Bundle = Bundle(for: Binder.self)) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: comment)
    }
}

// Use some Formatter to bind label
public extension UILabel {

    // MARK: - string

    /// Display a data with RFC 822 format
    @objc dynamic public var localized: String? {
        get {
            guard let localized = self.text else {
                return nil
            }
            return localized // Cannot undo it...
        }
        set {
            guard let string = newValue else {
                self.text = nil
                return
            }
            self.text = string.localizedBinding
        }
    }

    // MARK: - date

    /// Display a data with RFC 822 format
    @objc dynamic public var date: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.rfc822.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.rfc822.string(from: date)
        }
    }

    /// Display a data with a short style, typically numeric only, such as “11/23/37”.
    @objc dynamic public var shortDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.shortDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.shortDate.string(from: date)
        }
    }

    /// Display a data with a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    @objc dynamic public var mediumDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.mediumDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.mediumDate.string(from: date)
        }
    }

    /// Display a data with a long style, typically with full text, such as “November 23, 1937”.
    @objc dynamic public var longDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.longDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.longDate.string(from: date)
        }
    }

    /// Display a data with a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    @objc dynamic public var fullDate: Date? {
        get {
            guard let text = self.text else {
                return nil
            }
            return DateFormatter.fullDate.date(from: text)
        }
        set {
            guard let date = newValue else {
                self.text = nil
                return
            }
            self.text = DateFormatter.fullDate.string(from: date)
        }
    }

    // MARK: - time (duration)

    /// Display a time with a short style, typically numeric only, such as “3:30 PM”.
    @objc dynamic public var shortTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.short.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.short.string(from: number)
        }
    }

    /// Display a time with a medium style, typically with abbreviated text, such as “3:30:32 PM”.
    @objc dynamic public var mediumTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.medium.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.medium.string(from: number)
        }
    }

    /// Display a time with a long style, typically with full text, such as “3:30:32 PM PST”.
    @objc dynamic public var longTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.long.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.long.string(from: number)
        }
    }

    /// Display a time with a full style with complete details, such as “3:30:42 PM Pacific Standard Time”.
    @objc dynamic public var fullTime: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.full.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.full.string(from: number)
        }
    }

    // MARK: - bool

    /// Display 1 or 0 for boolean value
    @objc dynamic public var bool: Bool {
        get {
            return integer == 1
        }
        set {
            integer = newValue ? 1: 0
        }
    }

    @objc dynamic public var boolean: NSNumber? {
        get {
            return integer
        }
        set {
            integer = boolean
        }
    }

    /// Display yes or no for boolean value
    @objc dynamic public var yesOrNo: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "Yes".localizedFramework
        }
        set {
            text = newValue ? "Yes".localizedFramework: "No".localizedFramework
        }
    }

    /// Display true or false for boolean value
    @objc dynamic public var trueOrFalse: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "True".localizedFramework
        }
        set {
            text = newValue ? "True".localizedFramework: "False".localizedFramework
        }
    }

    // MARK: - number

    /// Display a number with a decimal style format; for example, 1234.5678 is represented as “1234.5678”.
    @objc dynamic public var decimal: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.decimal.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.decimal.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “$ 1234.57”.
    @objc dynamic public var currency: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currency.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currency.string(from: number)

        }
    }

    /// Display a number with a currency style format using ISO 4217 currency codes; for example, in the en_US_POSIX locale, 1234.5678 is represented as “USD 1234.57”.
    @objc dynamic public var currencyISOCode: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyISOCode.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyISOCode.string(from: number)

        }
    }

    /// Display a number with a percent style format; for example, 1234.5678 is represented as “123457%”.
    @objc dynamic public var percent: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.percent.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.percent.string(from: number)

        }
    }

    /// Display a number with no style, such that an integer representation is used; for example, 1234.5678 is represented as “1235”.
    @objc dynamic public var integer: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.none.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.none.string(from: number)

        }
    }

    /// Display a number with a spell-out format; for example, 1234.5678 is represented as “one thousand two hundred thirty-four point five six seven eight”.
    @objc dynamic public var spellOut: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.spellOut.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.spellOut.string(from: number)

        }
    }

    /// Display a number with an ordinal format; for example, in the en_US_POSIX locale, 1234.5678 is represented as “1,235th”
    @objc dynamic public var ordinal: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.ordinal.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.ordinal.string(from: number)

        }
    }
}

// MARK: image

import QMobileAPI
import QMobileDataSync
import Kingfisher
extension UILabel {
    @objc dynamic public var restImage: [String: Any]? {
        get {
            if let text = self.text {
                let deffered = Deferred(uri: text, image: true)
                return deffered.dictionary
            }
            return nil
        }
        set {
            guard let dico = newValue, let uri = ImportableParser.parseImage(dico) else {
                self.text = nil
                return
            }
            self.text = uri

            let restTarget = DataSync.instance.rest.base
            let urlString = restTarget.baseURL.absoluteString +
                (uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri)
            guard let components = URLComponents(string: urlString), let url = components.url else {
                self.text = nil
                return
            }

            let modifier = AnyModifier { request in
                return APIManager.instance.configure(request: request)
            }
            var options: KingfisherOptionsInfo = [.requestModifier(modifier)]
            var placeHolderImage: UIImage?
            if let builder = self as? KingfisherOptionsInfoBuilder {
                options = builder.option(for: url, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
            }

            let cacheKey = components.path.replacingOccurrences(of: "/"+restTarget.path+"/", with: "")
                .replacingOccurrences(of: "/", with: "")

            //let resource = ImageResource(downloadURL: url, cacheKey: cacheKey)
            let imageCache = options.targetCache

            if !imageCache.imageCachedType(forKey: cacheKey).cached {
                let subdirectory = ApplicationImageCache.subdirectory
                let ext = ApplicationImageCache.extension
                if let url = Bundle.main.url(forResource: cacheKey, withExtension: ext, subdirectory: subdirectory),
                    let image = Image(url: url) {
                    imageCache.store(image, forKey: cacheKey)
                    options += [.forceRefresh]
                }
            }
            //if imageCache.imageCachedType(forKey: cacheKey).cached {
            if let image = imageCache.retrieveImageInDiskCache(forKey: cacheKey) ?? placeHolderImage {
                let attachmentImage = NSTextAttachment()
                attachmentImage.image = image
                self.attributedText = NSAttributedString(attachment: attachmentImage)
            }
            //}

        }
    }

}
