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
        guard let unwrapped = string else {
            return nil
        }
        self.init(string: unwrapped)
    }

    public func value(forQueryItem name: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.filter({$0.name == name}).first?.value
    }

}

let validIpAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
extension URL {
    var isIpAddress: Bool {
        guard let host = self.host else { return false }
        guard !host.isEmpty else { return false }
        return host.range(of: validIpAddressRegex, options: .regularExpression) != nil
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
