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

    /// File name where to find localizedBinding. Default 'Formatters'.
    @nonobjc public static var localizedBindingTableName: String = "Formatters"

    /// Localized string for binding
    var localizedBinding: String {
        return NSLocalizedString(self, tableName: String.localizedBindingTableName, bundle: .uiBinding, comment: "")
    }

    /// Loocalized string found in this framework
    var localizedFramework: String {
        return NSLocalizedString(self, bundle: Bundle(for: Binder.self), comment: "")
    }

    func localized(with comment: String = "", bundle: Bundle = Bundle(for: Binder.self)) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: comment)
    }
}

/*
Make it generic with other text widget
 public protocol UITextOwner {
    var text: String? {get set}
    var attributedText: NSAttributedString? {get set}
}
extension UILabel: UITextOwner {}*/

// Use some Formatter to bind label
public extension UILabel {
    @objc dynamic public var systemToPosixPath: String? {
        get {
            // Return the original
            return text?.replacingOccurrences(of: "/", with: ":")
        }
        set {
            // Set the value you want to display
            self.text = text?.replacingOccurrences(of: ":", with: "/")
        }
    }
    // MARK: - string

    /// Display a localized bundle
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

    /// Display an image from bundle.
    @objc dynamic public var imageNamed: String? {
        get {
            return self.text // Cannot undo it without storing...
        }
        set {
            guard let name = newValue else {
                self.text = nil
                return
            }
            guard let image = UIImage(named: name) else {
                self.text = nil // XXX maybe instead add a missing image, a placeholder image?
                return
            }
            self.setImage(image)
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
    @objc dynamic public var noOrYes: Bool {
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
    @objc dynamic public var falseOrTrue: Bool {
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

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “$ 1234.57”.
    @objc dynamic public var currencyDollar: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyDollar.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyDollar.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example,  1234.5678 is represented as “1234,57 €”.
    @objc dynamic public var currencyEuro: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyEuro.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyEuro.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “£ 1234.57”.
    @objc dynamic public var currencyLivreSterling: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyLivreSterling.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyLivreSterling.string(from: number)

        }
    }

    /// Display a number with a currency style format; for example, 1234.5678 is represented as “¥ 1234”.
    @objc dynamic public var currencyYen: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return NumberFormatter.currencyYen.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = NumberFormatter.currencyYen.string(from: number)

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

    /// Display a number with no style, such that an integer representation is used; for example, 105.12345679111 is represented as “105.12345679”.
    @objc dynamic public var real: NSNumber? {
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
            self.text = number.description
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

    // MARK: simple string transforamtion

    @objc dynamic public var capitalised: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.capitalized

        }
    }

    @objc dynamic public var lowercased: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.lowercased()

        }
    }

    @objc dynamic public var uppercased: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.uppercased()
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
                return Deferred(uri: text, image: true).dictionary
            }
            return nil
        }
        set {
            guard let imageResource = ApplicationImageCache.imageResource(for: newValue) else {
                self.text = nil
                return
            }
            self.text = imageResource.downloadURL.absoluteString

            logger.verbose("Setting \(imageResource) to view \(self)")

            // Setup placeHolder image or other options defined by custom builders
            var options = ApplicationImageCache.options()
            var placeHolderImage: UIImage?
            if let builder = self as? ImageCacheOptionsBuilder {
                options = builder.option(for: imageResource.downloadURL, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
            }

            /// Check cache, bundle
            ApplicationImageCache.checkCached(imageResource)

            // Do the request
            let completionHandler: CompletionHandler = { [weak self] image, error, cacheType, imageURL in
                if let error = error {
                    ApplicationImageCache.log(error: error, for: imageURL)
                } else if let image = image {
                    self?.setImage(image)
                }
            }
            cancelDownloadTask()
            if let placeHolderImage = placeHolderImage {
                setImage(placeHolderImage)
            }
            let imageDownloader = KingfisherManager.shared
            let task = imageDownloader.retrieveImage(
                with: imageResource,
                options: options,
                progressBlock: nil,
                completionHandler: completionHandler)
            setImageTask(task)
        }
    }

    fileprivate func setImage(_ image: UIImage) {
        let attachmentImage = NSTextAttachment()
        attachmentImage.image = image
        self.attributedText = NSAttributedString(attachment: attachmentImage)
    }

    fileprivate func cancelDownloadTask() {
        imageTask?.cancel()
    }

    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? RetrieveImageTask
    }

    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
private var imageTaskKey: Void?
