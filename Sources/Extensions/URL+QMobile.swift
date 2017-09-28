//
//  URL+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension URL {

    /// Allows optional argument when creating a URL
    public init?(string: String?) {
        guard let s = string else {
            return nil
        }
        self.init(string: s)
    }

    public func value(forQueryItem name: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.filter({$0.name == name}).first?.value
    }
}

extension URLComponents {

    init?(string: String, parameters: [String: Any]?) {
        self.init(string: string)
        if let params = parameters {
            var queryItems = [URLQueryItem]()
            for param in params {
                queryItems.append(URLQueryItem(name: param.key, value: "\(param.value)"))
            }
            self.queryItems = queryItems
        }
    }
}
