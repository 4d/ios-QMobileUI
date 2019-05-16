//
//  IconLabel.swift
//  IconLabel
//
//  Created by Eric Marchand on 30/10/2017.
//  Copyright © 2017 4D. All rights reserved.
//

import UIKit

/// An `UILabel` with associated `UIImage`.
@IBDesignable
open class IconLabel: UILabel {

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.configureView()
    }

    // MARK: Label properties

    /// Padding between image and text.
    @IBInspectable open var image: UIImage? {
        didSet {
            configureView()
        }
    }

    /// Padding between image and text.
    @IBInspectable open var imagePadding: Int = 0 {
        didSet {
            configureView()
        }
    }

    /// Resize the image to fit parent view.
    @IBInspectable open var imageAspectFit: Bool = false {
        didSet {
            configureView()
        }
    }

    enum ImagePosition: String {
        case left
        case right
        case top
        case bottom
    }

    //swiftlint:disable:next identifier_name
    var _imagePosition: ImagePosition = .left {
        didSet {
            configureView()
        }
    }
    @IBInspectable open var imagePosition: String = ImagePosition.left.rawValue {
        didSet {
            _imagePosition = ImagePosition(rawValue: self.imagePosition) ?? .left
        }
    }

   /// If image rendering context is automatic, this boolean allow to choose between template or original.
   @IBInspectable open var imageContextTemplate: Bool = true

    // MARK: Configure views
    open func configureView() {
        let text = NSAttributedString(string: self.text ?? "")
        if let image = configureImage() {

            // Create attachment text with image
            let attachmentImage = NSTextAttachment()
            attachmentImage.image = image
            let mid = font.descender + font.capHeight
            attachmentImage.bounds = CGRect(x: 0,
                                       y: font.descender - image.size.height / 2 + mid + 2,
                                       width: image.size.width,
                                       height: image.size.height)

            // Create the final text
            let string = NSMutableAttributedString(string: "")
            switch _imagePosition {
            case .left:
                if case .alwaysTemplate = image.renderingMode {
                    // Fix an issue if no text before template image
                    string.append(NSAttributedString(string: " "))
                }
                string.append(NSAttributedString(attachment: attachmentImage))
                for _ in 0..<imagePadding {
                    string.append(NSAttributedString(string: " "))
                }
                string.append(text)
            case .right:
                string.append(text)
                for _ in 0..<imagePadding {
                    string.append(NSAttributedString(string: " "))
                }
                string.append(NSAttributedString(attachment: attachmentImage))
            case .top:
                if case .alwaysTemplate = image.renderingMode {
                    // Fix an issue if no text before template image
                    string.append(NSAttributedString(string: " "))
                }
                string.append(NSAttributedString(attachment: attachmentImage))
                string.append(NSAttributedString(string: "\n"))
                string.append(text)
            case .bottom:
                string.append(text)
                string.append(NSAttributedString(string: "\n"))
                string.append(NSAttributedString(attachment: attachmentImage))
            }

            self.attributedText = string
        } else {
            self.attributedText = text
        }

       // configureUnderline()
    }

    open func configureImage() -> UIImage? {
        if let image = image {
            let renderingMode = configureRenderingMode(for: image)
            if imageAspectFit {
                let newSize = CGSize(width: self.frame.size.height, height: self.frame.size.height)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
                let attachmentImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return attachmentImage?.withRenderingMode(renderingMode)
            } else {
                return image.withRenderingMode(renderingMode)
            }
        }
        return nil
    }
    open func configureRenderingMode(for image: UIImage) -> UIImage.RenderingMode {
        switch image.renderingMode {
        case .alwaysOriginal:
            return .alwaysOriginal
        case .alwaysTemplate:
            return .alwaysTemplate
        case .automatic:
            return imageContextTemplate ? .alwaysTemplate : .alwaysOriginal
        @unknown default:
            return .alwaysOriginal
        }
    }

   /* let underline: UIView = UIView()
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUnderlineFrame()
    }
    
    func configureUnderline() {
        if isUnderLine {
            updateUnderlineFrame()
            underline.backgroundColor = underlineColor
            addSubview(underline)
        }
    }
    func updateUnderlineFrame() {
        underline.frame = CGRect(x: 0, y: frame.size.height-1, width: frame.size.width, height: 1)
    }
    
    @IBInspectable var underlineColor: UIColor = .black {
        didSet{
            self.updateView()
        }
    }
    
    @IBInspectable var isUnderLine: Bool = false {
        didSet{
            updateView()
        }
    }*/

}
