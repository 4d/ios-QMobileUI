//
//  FeedbackTarget.swift
//  QMobileUI
//
//  Created by phimage on 31/10/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

class FeedbackTarget: CrashTarget {

    override init(fileURL: URL, parameters: [String: String]) {
        super.init(fileURL: fileURL, parameters: parameters)
    }

    override var baseURL: URL {
        if let url = Prephirences.sharedInstance["feedback.server.url"] as? URL {
            return url
        }
        return super.baseURL
    }

    override var path: String {
        if let path = Prephirences.sharedInstance["feedback.server.path"] as? String {
            return path
        }
        return super.path
    }
}
