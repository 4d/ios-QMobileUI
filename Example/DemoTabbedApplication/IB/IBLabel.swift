//
//  IBLabel.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 13/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

private var xoAssociationeKey: UInt8 = 0
@IBDesignable
class IBLabel: UILabel {

    public var bindTest: IBLabelBinder! {
        get {
            var bindTo = objc_getAssociatedObject(self, &xoAssociationeKey) as? IBLabelBinder
            if bindTo == nil { // XXX check multithread  safety
                bindTo = IBLabelBinder(view: self)
                self.bindTest = bindTo
            }
            return bindTo
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationeKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

}


open class IBLabelBinder: NSObject {
    
    // MARK: attribute
    weak open var view: UIView?
    
    // MARK: init
    internal init(view: UIView) {
        self.view = view
    }

    
    // MARK: override KVC codding
    open override func value(forUndefinedKey key: String) -> Any? {
        // record undefined for setValue
        return self
    }
    
    open override func value(forKey key: String) -> Any? {
        return super.value(forKey: key)
    }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if let viewKey = value as? String, let view = self.view {
            
            let previousValue = view.value(forKey: viewKey)
            if previousValue == nil || ((previousValue as? String)?.isEmpty ?? false) {
                
                let value = "[table]\(key)"
                view.setValue(value, forKey: viewKey)
            }
            
            //let info =  ProcessInfo.processInfo.environment["IB_PROJECT_SOURCE_DIRECTORIES"]
            // view.setValue(info, forKey: viewKey)
        }
    }

}

import UIKit

// defined main attribute for UI component to display in InterfaceBuilder
public protocol IBAttributable {
    var ibAttritutable: String? {get set}
    var ibAttritutableKey: String {get}
}

extension UILabel: IBAttributable {
    public var ibAttritutable: String? {
        get {
            if self.text?.isEmpty ?? false {
                return nil
            }
            return self.text
        }
        set {
            self.text = newValue
        }
    }
    public var ibAttritutableKey: String { return "text" }
}
extension UITextView: IBAttributable {
    public var ibAttritutable: String? {
        get {
            if self.text?.isEmpty ?? false {
                return nil
            }
            return self.text
        }
        set {
            self.text = newValue
        }
    }
    public var ibAttritutableKey: String { return "text" }
}
extension UITextField: IBAttributable {
    public var ibAttritutable: String? {
        get {
            if self.text?.isEmpty ?? false {
                return nil
            }
            return self.text
        }
        set {
            self.text = newValue
        }
    }
    public var ibAttritutableKey: String { return "text" }
}

extension UIImageView: IBAttributable {
    public var ibAttritutable: String? {
        get {
            guard let image = self.image else {
                return nil
            }
            return "an image \(image)"
        }
        set {
            if let text = newValue {
                self.image = UIImage.image(from: text, size: self.frame.size)
            } else {
                self.image = nil
            }
        }
    }
    public var ibAttritutableKey: String { return "image" }
}


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
