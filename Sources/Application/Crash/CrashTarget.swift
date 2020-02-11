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
class CrashTarget: TargetType {

    let fileURL: URL
    let parameters: [String: String]
    let method: Moya.Method  = .post

    init(fileURL: URL, parameters: [String: String]) {
        self.fileURL = fileURL
        self.parameters = parameters
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
    var task: Task {
        var multipartFormData: [MultipartFormData] = [MultipartFormData(provider: .file(self.fileURL), name: "file", fileName: "data.zip", mimeType: "application/zip")]
        for (key, value) in self.parameters {
            multipartFormData.append(MultipartFormData(provider: .data(value.data(using: .utf8)!), name: key, mimeType: "text/plain"))
        }
        return .uploadMultipart(multipartFormData)
    }

    var sampleData: Data {
        return stubbedData("crashLog")
    }

    var headers: [String: String]? {
        return nil
    }

    var validationType: ValidationType {
        return .successCodes
    }

}

extension CrashTarget: DecodableTargetType {

    public typealias ResultType = CrashStatus
}
