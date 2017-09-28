//
//  String+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Guitar

extension String {

    public var firstLetter: String {
        guard let firstLetter = self.characters.first else {
            return ""
        }
        return String(firstLetter)
    }

    public var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest   = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    var htmlToAttributedString: NSAttributedString {
        do {
            if let data = data(using: .utf8) {
                let string = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8], documentAttributes: nil)
                return string
            }
        } catch {
            // CLEAN Ignore (bad practice) ignoring exception
        }
        return NSAttributedString(string: self)
    }

    var camelFirst: String {
        var newString: String = ""

        let upperCase = CharacterSet.uppercaseLetters
        var first = true
        for scalar in self.unicodeScalars {
            if first {
                first = false
            } else if upperCase.contains(scalar) {
                break
            }
            let character = Character(scalar)
            newString.append(character)

        }

        return newString
    }

    init(unwrappedDescrib object: Any?) {
        if let object = object {
            self.init(describing: object)
        } else {
            self.init(describing: object)
        }
    }

    var boolValue: Bool {
        return (Int(self) ?? 0) != 0
    }
}

extension String {

    // Case applied to view key in binding
    var viewKeyCased: String {
        return self.camelCased()
    }

}