//
//  SimpleYAMLEncoder.swift
//  QMobileUI
//
//  Created by Eric Marchand on 10/09/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation

class SimpleYAMLEncoder {

    enum NodeType {
        case scalar, sequence, mapping
    }

    var lineDelimiter: String = "\n"
    var paddingString: String = " "
    static let `default` = SimpleYAMLEncoder()

    public func encode(_ object: Any) -> String {
        var string: String = ""
        encodeTo(&string, object)
        return string
    }

    public func encodeTo(_ output: inout String, _ object: Any, _ padding: Int = 0, _ previous: NodeType = .scalar) {
        // Scalar
        if let value = object as? String {
            output+=value
        } else if let value = object as? Bool {
            output+=value ? "true" : "false"
        } else if let value = object as? NSNumber {
            output+=value.stringValue
        }
        // Mapping
        else if let values = object as? [String: Any] {

            if values.isEmpty {
                output+="{}"
            } else {
                var applyPadding = padding
                var othersPadding = padding
                switch previous {
                case .mapping:
                    output+="\(lineDelimiter)" // key is before
                case .scalar:
                    break
                case .sequence:
                    applyPadding = 0
                    othersPadding = padding + 2 // "- "
                }
                var first = true
                for (key, value) in values {
                    if first {
                        first = false
                    } else {
                        output+="\(lineDelimiter)"
                    }
                    output+="".padding(toLength: applyPadding, withPad: paddingString, startingAt: 0)
                    output+="\(key): "
                    encodeTo(&output, value, padding+2, .mapping)
                    applyPadding = othersPadding

                }
            }
        }
        // Sequence
        else if let values = object as? [Any] {
            if values.isEmpty {
                output+="[]"
            } else {
                var applyPadding = padding
                if previous == .sequence {
                    applyPadding += 2
                }

                // var first = true
                for value in values {
                    output+="\(lineDelimiter)"
                    output+="".padding(toLength: applyPadding, withPad: paddingString, startingAt: 0)
                    output+="- "
                    encodeTo(&output, value, padding, .sequence)
                    // first = false
                }
            }
        } else {
            // not implemented
            logger.debug("not implemented yaml encoding of \(object)")
        }
    }
}
