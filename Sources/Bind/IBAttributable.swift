//
//  IBAttributable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 13/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

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
