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
    fileprivate func sanitized() -> String {
        return replaceMatching(regex: .nonAlphanumeric, with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    public func pascalCased() -> String {
        return sanitized().splitWordsByCase().capitalized().components(separatedBy: .whitespaces).joined()
    }
    public func camelCased() -> String {
        return pascalCased().decapitalized()
    }

    public func capitalized() -> String {
        let ranges = self.ranges(regex: .firstCharacter)

        var newString = self
        for range in ranges {
            let character = index(range.lowerBound, offsetBy: 0)
            let uppercasedCharacter = String(self[character]).uppercased()
            newString = newString.replacingCharacters(in: range, with: uppercasedCharacter)
        }

        return newString
    }

    public func decapitalized() -> String {
        let ranges = self.ranges(regex: .firstCharacter)

        var newString = self
        for range in ranges {
            let character = self[range.lowerBound]
            let lowercasedCharacter = String(character).lowercased()
            newString = newString.replacingCharacters(in: range, with: lowercasedCharacter)
        }

        return newString
    }

    fileprivate func ranges(regex: NSRegularExpression) -> [Range<String.Index>] {
        let string = self
        let range = NSRange(location: 0, length: string.utf16.count)

        let matches = regex.matches(in: string, options: [], range: range)
        let ranges = matches.compactMap { (match) -> Range<String.Index>? in
            let nsRange = match.range
            return nsRange.range(for: string)
        }
        return ranges
    }
    fileprivate func replaceMatching(regex: NSRegularExpression, with character: String) -> String {
        let ranges = self.ranges(regex: regex)

        var newString = self
        for range in ranges {
            newString.replaceSubrange(range, with: character)
        }

        return newString
    }
    fileprivate func splitWordsByCase() -> String {
        var newStringArray: [String] = []
        for character in sanitized() {
            if String(character) == String(character).uppercased() {
                newStringArray.append(" ")
            }
            newStringArray.append(String(character))
        }

        return newStringArray
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter({ !$0.isEmpty })
            .joined(separator: " ")
    }

    // Case applied to view key in binding
    var viewKeyCased: String {
        return self.camelCased()
    }

}

extension NSRange {
    fileprivate func range(for string: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }

        guard let fromUTFIndex = string.utf16.index(string.utf16.startIndex, offsetBy: location, limitedBy: string.utf16.endIndex) else { return nil }
        guard let toUTFIndex = string.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: string.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: string) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: string) else { return nil }

        return fromIndex ..< toIndex
    }
}
