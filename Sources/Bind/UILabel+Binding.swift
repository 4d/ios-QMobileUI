//
//  UILabel+Binding.swift
//  Invoices
//
//  Created by Eric Marchand on 31/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileAPI

/*
Make it generic with other text widget
 public protocol UITextOwner {
    var text: String? {get set}
    var attributedText: NSAttributedString? {get set}
}
extension UILabel: UITextOwner {}*/

// Use some Formatter to bind label
public extension UILabel {
    @objc dynamic var systemToPosixPath: String? {
        get {
            // Return the original
            return text?.replacingOccurrences(of: "/", with: ":")
        }
        set {
            // Set the value you want to display
            self.text = newValue?.replacingOccurrences(of: ":", with: "/")
        }
    }
    // MARK: - string

    /// Display a localized text found in Formatters.strings
    @objc dynamic var localizedText: String? {
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

    /// Display an image from asset.
    @objc dynamic var imageNamed: String? {
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

    @objc dynamic var systemImageNamed: String? {
        get {
            return self.text // Cannot undo it without storing...
        }
        set {
            guard let name = newValue else {
                self.text = nil
                return
            }
            guard let image = UIImage(systemName: name) else {
                self.text = nil // XXX maybe instead add a missing image, a placeholder image?
                return
            }
            self.setImage(image)
        }
    }

    // MARK: - date

    /// Display a date with RFC 822 format
    @objc dynamic var date: Date? {
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

    /// Display a date with a short style, typically numeric only, such as “11/23/37”.
    @objc dynamic var shortDate: Date? {
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

    /// Display a date with a medium style, typically with abbreviated text, such as “Nov 23, 1937”.
    @objc dynamic var mediumDate: Date? {
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

    /// Display a date with a long style, typically with full text, such as “November 23, 1937”.
    @objc dynamic var longDate: Date? {
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

    /// Display a date with a full style with complete details, such as “Tuesday, April 12, 1952 AD”.
    @objc dynamic var fullDate: Date? {
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
    @objc dynamic var shortTime: NSNumber? {
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
    @objc dynamic var mediumTime: NSNumber? {
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
    @objc dynamic var longTime: NSNumber? {
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
    @objc dynamic var fullTime: NSNumber? {
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

    /// Display a time with a short style, typically numeric only, such as “3:30”.
    @objc dynamic var duration: NSNumber? {
        get {
            guard let text = self.text else {
                return nil
            }
            return TimeFormatter.simple.number(from: text)
        }
        set {
            guard let number = newValue else {
                self.text = nil
                return
            }
            self.text = TimeFormatter.simple.string(from: number)
        }
    }

    // MARK: - bool

    /// Display 1 or 0 for boolean value
    @objc dynamic var bool: Bool {
        get {
            return integer == 1
        }
        set {
            integer = newValue ? 1: 0
        }
    }

    @objc dynamic var boolean: NSNumber? {
        get {
            return integer
        }
        set {
            integer = newValue
        }
    }

    /// Display yes or no for boolean value
    @objc dynamic var noOrYes: Bool {
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
    @objc dynamic var falseOrTrue: Bool {
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
    @objc dynamic var decimal: NSNumber? {
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
    @objc dynamic var currencyDollar: NSNumber? {
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
    @objc dynamic var currencyEuro: NSNumber? {
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
    @objc dynamic var currencyLivreSterling: NSNumber? {
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
    @objc dynamic var currencyYen: NSNumber? {
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
    @objc dynamic var percent: NSNumber? {
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
    @objc dynamic var real: NSNumber? {
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
    @objc dynamic var integer: NSNumber? {
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
    @objc dynamic var spellOut: NSNumber? {
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
    @objc dynamic var ordinal: NSNumber? {
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

    @objc dynamic var capitalised: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.capitalized

        }
    }

    @objc dynamic var lowercased: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.lowercased()

        }
    }

    @objc dynamic var uppercased: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.text = newValue?.uppercased()
        }
    }

    @objc dynamic var htmlText: String? {
        get {
            return self.text // N.B. no reverse transformation
        }
        set {
            self.attributedText = newValue?.htmlToAttributedString
        }
    }

}

// MARK: image

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
            let completionHandler: UIImageView.ImageCompletionHandler = { result in
                switch result {
                case .success(let value):
                    self.setImage(value.image)
                case .failure(let error):
                    ApplicationImageCache.log(error: error, for: imageResource.downloadURL)
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
        attachmentImage.setImageHeight(height: 200)
        self.attributedText = NSAttributedString(attachment: attachmentImage)
        self.textAlignment = .center
    }

    func firstImage(textStorage: NSAttributedString) -> UIImage? {
        for idx in 0 ..< textStorage.string.count {
            if let attr = textStorage.attribute(NSAttributedString.Key.attachment, at: idx, effectiveRange: nil),
                let attachment = attr as? NSTextAttachment,
                let image = attachment.image {
                return image
            }
        }
        return nil
    }

    fileprivate func cancelDownloadTask() {
        imageTask?.cancel()
    }

    fileprivate var imageTask: DownloadTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? DownloadTask
    }

    fileprivate func setImageTask(_ task: DownloadTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
private var imageTaskKey: Void? // swiftlint:disable:this file_length

extension NSTextAttachment {
    func setImageHeight(height: CGFloat) {
        guard let image = image else { return }
        if image.size.width >= image.size.height {
            let ratio = image.size.width / image.size.height
            bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: ratio * height, height: height)
        } else {
            let ratio = image.size.width / image.size.height
            bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: height, height: height / ratio)
        }
    }
}
