//
//  File.swift
//  QMobileUI
//
//  Created by phimage on 31/10/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

import Moya
import QMobileAPI

/// CrashStatus of 4D rest server.
public struct CrashStatus {

    static let okKey = "ok"
    static let successKey = "success"

    /// `true` if server ok
    public var ok: Bool // swiftlint:disable:this identifier_name

    public init(ok: Bool) { // swiftlint:disable:this identifier_name
        self.ok = ok
    }

}

extension CrashStatus: JSONDecodable {

    public init?(json: JSON) {
        ok = json[CrashStatus.okKey].bool ?? json[CrashStatus.successKey].boolValue
    }
}

// MARK: DictionaryConvertible
extension CrashStatus: DictionaryConvertible {

    public var dictionary: DictionaryConvertible.Dico {
        var dictionary: DictionaryConvertible.Dico = [:]
        dictionary[CrashStatus.okKey] = self.ok
        return dictionary
    }

}

// MARK: Equatable
extension CrashStatus: Equatable {
    public static func == (lhf: CrashStatus, rhf: CrashStatus) -> Bool {
        return lhf.ok == rhf.ok
    }
}
