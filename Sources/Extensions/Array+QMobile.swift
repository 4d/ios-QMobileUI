//
//  Array+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 14/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Array where Element: AnyObject {
    /// Delete comparing using ===
    /// Use a `Set` or use index if you can for more efficiency
    mutating func delete(_ element: Element) {
        self = self.filter { $0 !== element }
    }
}
extension Array where Element: Any {
    /// Return list of objects of specified `type`.
    func objects<T>(of type: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }
}

func flatten<T>(value: T, childrenClosure: (T) -> [T]) -> [T] {
    var result: [T] = childrenClosure(value)
    result = result.flatMap { flatten(value: $0, childrenClosure: childrenClosure) }
    return [value] + result
}

/*func filter<T>(isIncluded: (T) -> Bool, value: T, childrenClosure: (T) -> [T]) -> [T] {
    let children: [T] = childrenClosure(value)
    var result: [T] = children.filter(isIncluded)
    result += children.flatMap { filter(isIncluded: isIncluded, value: $0, childrenClosure: childrenClosure) }

    if isIncluded(value) {
        return [value] + result
    }
    return result
}*/

func filter<T, U>(value: T, childrenClosure: (T) -> [T]) -> [U] {
    let children: [T] = childrenClosure(value)
    var result: [U] = children.objects(of: U.self)
    result += children.flatMap { filter(value: $0, childrenClosure: childrenClosure) }

    if let filtered = value as? U {
        return [filtered] + result
    }
    return result
}
