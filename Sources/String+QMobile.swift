//
//  String+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension String {

    public var firstLetter: String {
        guard let firstLetter = self.characters.first else {
            return ""
        }
        return String(firstLetter)
    }

    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    public func localized(with comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
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

    var camelFirst: String? {
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

}

extension String {

    public enum Case {
        case lower
        case upper
        case capitalized
        case upperCamel
        case lowerCamel
        case snake
        case kebab
    }

    func to(case stringCase: Case) -> String {
        switch stringCase {
        case .lower:
            return self.lowercased()
        case .upper:
            return self.uppercased()
        case .capitalized:
            return self.capitalized
        case .upperCamel:
            return self.camelcased(uppercaseFirst: true)
        case .lowerCamel:
            return self.camelcased(uppercaseFirst: false)
        case .snake:
            return self.underscored()
        case .kebab:
            return self.kebabCased()
        }
    }

    public func camelcased(uppercaseFirst: Bool = false) -> String {
        return self.replacingMatches(of: " +", with: "_")
            .components(separatedBy: "_")
            .enumerated().map { (index, part) in
                if index == 0 && !uppercaseFirst {
                    return part.lowercased()
                } else {
                    return part.capitalized
                }
            }.joined()
    }

    private func joiningWords(with separator: String) -> String {
        return self
            .replacingMatches(of: "([A-Z]+)([A-Z][a-z])", with: "$1\(separator)$2")
            .replacingMatches(of: "([a-z\\d])([A-Z])", with: "$1\(separator)$2")
            .replacingMatches(of: "[- ]", with: separator)
    }

    public func underscored() -> String {
        return self.joiningWords(with: "_").lowercased()
    }

    public func kebabCased() -> String {
        return self.joiningWords(with: "-").lowercased()
    }

    func replacingMatches(of pattern: String, options: NSRegularExpression.MatchingOptions = [], with template: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            return regex.stringByReplacingMatches(in: self, options: options, range: NSRange(0..<self.characters.count), withTemplate: template)
        } catch _ {
            return self
        }
    }
}
