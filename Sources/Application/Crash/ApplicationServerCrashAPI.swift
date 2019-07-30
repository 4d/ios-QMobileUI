//
//  ApplicationServerCrashAPI.swift
//  QMobileUI
//
//  Created by anass talii on 29/03/2018.
//  Copyright © 2018 Anass. All rights reserved.
//

import Foundation
import Prephirences

import Moya
import QMobileAPI

/// Target to send crash file
struct ApplicationServerCrashAPI {

    let fileURL: URL
    let parameters: [String: String]
    let method: Moya.Method  = .post

    init(fileURL: URL, parameters: [String: String]) {
        self.fileURL = fileURL
        self.parameters = parameters
    }
}

extension ApplicationServerCrashAPI: TargetType {

    var task: Task {
        return .uploadFile(self.fileURL)
    }

    var baseURL: URL {
        if let url = Prephirences.sharedInstance["crash.server.url"] as? URL {
            return url
        }
        if let urlString = Prephirences.sharedInstance["crash.server.url"] as? String,
            let url = URL(string: urlString) {
            return url
        }
        return URL.qmobileLocalhost
    }

    var path: String {
        if let path = Prephirences.sharedInstance["crash.server.path"] as? String {
            return path
        }
        return "4daction/MobileAppCrash"
    }

    var sampleData: Data {
        return stubbedData("crashLog")
    }

    var headers: [String: String]? {
        return self.parameters
    }

    var validationType: ValidationType {
        return .successCodes
    }

}

extension ApplicationServerCrashAPI: DecodableTargetType {

    public typealias ResultType = CrashStatus
}

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
