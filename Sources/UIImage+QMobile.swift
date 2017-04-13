//
//  UIImage+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIImage {

    class func image(from text: String, size: CGSize, textSize: CGFloat = 24, color: UIColor = UIColor.black) -> UIImage {

        let data = text.data(using: .utf8, allowLossyConversion: true)
        let drawText = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)

        let font = UIFont.systemFont(ofSize: textSize)
        let textFontAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: color]

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

}
