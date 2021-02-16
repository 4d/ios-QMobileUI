//
//  UIImage+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

    class func image(from text: String, size: CGSize, textSize: CGFloat = 24, color: UIColor = UIColor.black) -> UIImage {

        let data = text.data(using: .utf8, allowLossyConversion: true)
        let drawText = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)

        let font = UIFont.systemFont(ofSize: textSize)
        let textFontAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]

        let widthOfText = widthForView(text: text, font: font, height: size.height)
        let heightOfText = heightForView(text: text, font: font, width: size.width)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        drawText?.draw(in: CGRect(x: (size.width - widthOfText) / 2, y: (size.height - heightOfText) / 2, width: size.width, height: size.height),
                       withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    fileprivate static func widthForView(text: String, font: UIFont, height: CGFloat) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: height))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.width
    }

    fileprivate static func heightForView(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }

    func resizeImage(targetSize: CGSize) -> UIImage {
        let image = self
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

}

extension Array where Element == UIImage {

    func mergeToGrid() -> UIImage? {
        if isEmpty {
            return nil
        }
        if count == 1 {
            return first
        }
        let images = self.compactMap({$0})
        let padding: CGFloat = 0
        var first = images[0]
        first =  images[0].resizeImage(targetSize: CGSize(width: 100, height: first.size.height * 100 / first.size.width)) // resize to speed up
        let newWidth = first.size.width * 2 + padding * 3
        let newHeight = first.size.height + padding * 3
        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)

        for (index, element) in images.enumerated() {
            let xIndex = CGFloat(index % 2)
            let x = xIndex * (first.size.width + padding) + padding // swiftlint:disable:this identifier_name
            let yIndex = floor(CGFloat(index) / 2)
            let y = yIndex * (first.size.height + padding) + padding // swiftlint:disable:this identifier_name
            element.draw(in: CGRect(origin: CGPoint(x: Double(x), y: Double(y)), size: first.size))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

}
