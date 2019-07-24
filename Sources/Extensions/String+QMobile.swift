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
        guard let firstLetter = self.first else {
            return ""
        }
        return String(firstLetter)
    }

    var htmlToAttributedString: NSAttributedString {
        guard let data = data(using: .utf8) else { return NSAttributedString(string: self) }

        return (try? NSAttributedString(data: data,
                                       options: [.documentType: NSAttributedString.DocumentType.html,
                                                 .characterEncoding: String.Encoding.utf8],
                                       documentAttributes: nil)) ?? NSAttributedString(string: self)
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

// MARK: Mail

private extension NSRegularExpression {
    static let email = try? NSRegularExpression(pattern: "^"+String.emailRegex, options: [])
}
private extension NSPredicate {
    static let email = NSPredicate(format: "SELF MATCHES %@", String.emailRegex)
}

extension String {

    static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"

    public var isValidEmail: Bool {
        return NSPredicate.email.evaluate(with: self)
    }

}
