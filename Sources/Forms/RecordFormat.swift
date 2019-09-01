//
//  RecordFormatter.swift
//  QMobileUI
//
//  Created by Eric Marchand on 30/08/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore
import QMobileDataSync

// XXX to move

/// a formatter for record name attributes
struct RecordFormatter {

    enum Token {
        case field(String, CountableRange<Int>)
        case fieldOriginal(String, CountableRange<Int>)
        case undefined(String, CountableRange<Int>)
    }

    class Lexer {
        typealias TokenBuilder = (String, CountableRange<Int>) -> Token? //swiftlint:disable:this nesting
        static let tokenStringList: [String: TokenBuilder] = [
            ":[a-zA-Z][a-zA-Z0-9]*": ({ .field($0, $1) }),
            "%[\\w ]*%": ({ .fieldOriginal($0, $1) })
        ]
        typealias TokenRegularExpression = (NSRegularExpression, TokenBuilder) //swiftlint:disable:this nesting
        static let tokenList: [TokenRegularExpression] = tokenStringList.map {
            (try! NSRegularExpression(pattern: "^\($0.0)", options: []), $0.1) //swiftlint:disable:this force_try
        }
        /// Split input string to tokens
        static func tokenize(_ input: String) -> [Token] {
            var tokens = [Token]()
            var content = input
            while !content.isEmpty {
                var found = false
                for (regex, builder) in tokenList {
                    if let (matched, range) = regex.matched(content) {
                        if let token = builder(matched, range) {
                            tokens.append(token)
                        }
                        // next content
                        content = String(content[content.index(content.startIndex, offsetBy: matched.count)...])
                        found = true
                        break
                    }
                }

                if !found {
                    let index = content.index(content.startIndex, offsetBy: 1)
                    let intIndex = content.distance(from: content.startIndex, to: index)
                    tokens.append(.undefined(String(content[..<index]), intIndex..<intIndex + 1))
                    content = String(content[index...])
                }
            }
            return tokens
        }
    }

    class Parser {

        let tokens: [Token]
        var currentIndex = 0

        init(tokens: [Token]) {
            self.tokens = tokens
        }

        // MARK: current token

        func currentToken() -> Token {
            if currentIndex >= tokens.count {
                return .undefined("", 0..<0)
            }
            return tokens[currentIndex]
        }

        @discardableResult
        func popCurrentToken() -> Token {
            defer { currentIndex += 1 }
            return tokens[currentIndex]
        }

        // MARK: parse

        func parse() throws -> [Node] {
            currentIndex = 0
            var nodes = [Node]()
            while currentIndex < tokens.count {
                let expr = try parseExpression()
                nodes.append(expr)
            }
            return nodes
        }

        func parseExpression() throws -> Node {
            return try parsePrimary()
        }

        func parsePrimary() throws -> Node {
            _ = self.currentToken()
            return try parseIdentifier()
        }

        func parseIdentifier() throws -> Node {
            let firstToken = popCurrentToken()
            switch firstToken {
            case .undefined(let name, _):
                return UndefinedNode(name: name)
            case .field(let name, _):
                return FieldNode(name: String(name.dropFirst()))
            case .fieldOriginal(let name, _):
                return FieldOriginalNode(name: String(name.dropFirst().dropLast()))
            }
        }
    }

    var nodes: [Node]
    var tableInfo: DataStoreTableInfo
    init?(format: String, tableInfo: DataStoreTableInfo) {
        guard let nodes = try? Parser(tokens: Lexer.tokenize(format)).parse() else {
            return nil
        }
        self.tableInfo = tableInfo
        self.nodes = nodes.compact() // XXX better lexer or merge simple node?
    }

    func format(_ object: AnyObject) -> String {
        var string = ""
        for node in nodes {
            string += node.format(object, tableInfo: tableInfo)
        }
        return string
    }

}

extension Array where Element: Node {

    func compact() -> [Node] {
        var newNodes: [Node] = []
        var currentNode: Node?
        for node in self {
            if node is UndefinedNode {
                if let toAppend = currentNode {
                    currentNode = UndefinedNode(name: toAppend.name + node.name)
                } else {
                    currentNode = node
                }
            } else {
                if let toAppend = currentNode {
                    newNodes.append(toAppend)
                    currentNode = nil
                }
                newNodes.append(node)
            }
        }
        if let toAppend = currentNode {
            newNodes.append(toAppend)
        }
        return newNodes
    }
}

class Node: CustomStringConvertible, Equatable {
    var range: CountableRange<Int> = 0..<0
    let name: String

    init(name: String) {
        self.name = name
    }

    var description: String {
        return "\(type(of: self))(name: \"\(name)\")"
    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.description == rhs.description
    }

    func format(_ object: AnyObject, tableInfo: DataStoreTableInfo) -> String {
        return name
    }

}

class UndefinedNode: Node {}

class FieldNode: Node {

    override func format(_ object: AnyObject, tableInfo: DataStoreTableInfo) -> String {
        if let value = object.value(forKeyPath: name) {
            return "\(value)"
        }
        return name
    }

}

class FieldOriginalNode: Node {

    override func format(_ object: AnyObject, tableInfo: DataStoreTableInfo) -> String {
        if let field = tableInfo.fields.filter({ $0.originalName == self.name}).first,
            let value = object.value(forKeyPath: field.name) {
            return "\(value)"
        }
        return name
    }

}
