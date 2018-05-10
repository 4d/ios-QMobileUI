//
//  ApplicationServerCrashAPI.swift
//  QMobileUI
//
//  Created by anass talii on 29/03/2018.
//  Copyright © 2018 Anass. All rights reserved.
//

import Foundation
import Moya

extension URL {
    static var httpLocalIP = URL(string: "http://127.0.0.1")!
    static var httpLocalhost = URL(string: "http://localhost")!
    
    static var httpsLocalIP = URL(string: "https://127.0.0.1")!
    static var httpsLocalhost = URL(string: "https://localhost")!
}

struct ApplicationServerCrashAPI {
    let fileName : URL
    let parametre : Dictionary<String, String>
}

extension CrashServerAPI: TargetType {
    
    init(zipFile: URL, param: Dictionary<String,String>) {
        self.fileName = zipFile
        self.parametre = param
    }
    
    var task: Task {
        return .uploadFile(self.fileName)
    }
    
    var baseURL: URL {
        return URL.httpLocalIP
    }
    
    var path: String {
        return "/4daction/LogReceive"
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data {
        return jsonSerializedUTF8(json: self.parametre)
    }
    
    var headers: [String : String]? {
        return self.parametre
    }
    
    var parameters: [String: String]? {
        return self.parametre
    }
    
    private func jsonSerializedUTF8(json: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
    }
}


