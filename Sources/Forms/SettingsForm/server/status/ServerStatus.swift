//
//  ServerStatus .swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI

/// Server status
public enum ServerStatus {
    /// Not determined yet
    case unknown
    /// URL has no text
    case emptyURL
    /// Could not create a valid URL
    case notValidURL
    /// Not a valid url scheme (http or https)
    case notValidScheme
    /// Checking status
    case checking
    /// Status checked with a result
    case done(ServerStatusResult)
}

public typealias ServerStatusResult = Result<Status, APIError>

extension ServerStatus {

    public var isChecking: Bool {
        switch self {
        case .checking: return true
        default: return false
        }
    }

    public var isFinal: Bool {
        return !isChecking
    }
    public var isSuccess: Bool {
        if case .done(let result) = self {
            if case .success = result {
                return true
            }
        }
        return false
    }
    public var isSuccessAuthentified: Bool {
        if case .done(let result) = self {
            if case .success(let status) = result {
                return status.ok
            }
        }
        return false
    }

    public var isFailure: Bool {
        // CLEAN : make a switch
        if case .done(let result) = self {
            if case .failure = result {
                return true
            }
            if case .success(let status) = result {
                return !status.ok
            }
        }
        if case .emptyURL = self {
            return true
        }
        if case .notValidURL = self {
            return true
        }
        if case .notValidScheme = self {
            return true
        }

        return false
    }
}

extension ServerStatus {

    public var message: String {
        switch self {
        case .unknown:
            return ""
        case .emptyURL:
            return "Please enter the server URL"
        case .notValidURL, .notValidScheme:
            return "Please enter a valid URL (https://hostname)"
        case .checking:
            return "Checking server accessibility..."
        case .done (let result):
            switch result {
            case .success:
                return "Server is online"
            case .failure:
                return "Server is not accessible"
            }
        }
    }

    public var detailMessage: String {
        switch self {
        case .done (let result):
            switch result {
            case .success:
                return ""
            case .failure(let error):
                if let afError = error.afError {
                    if case .sessionTaskFailed(let urlError)  = afError {
                        return urlError.localizedDescription
                    }
                }
                let failureReason = error.failureReason ?? ""
                return "\(failureReason)"
            }
        default:
            return ""
        }
    }
}

extension ServerStatus: Equatable {
    public static func == (left: ServerStatus, rigth: ServerStatus) -> Bool {
        switch (left, rigth) {
        case (.unknown, .unknown): return true
        case (.emptyURL, .emptyURL): return true
        case (.notValidURL, .notValidURL): return true
        case (.notValidScheme, .notValidScheme): return true
        case (.checking, .checking): return true
        case (.done(let result), .done (let result2)):
            switch (result, result2) {
            case (.success, .success): return true
            case (.failure(let error), .failure(let error2)):
                return error.failureReason ==  error2.failureReason
            default: return false
            }
        default: return false
        }
    }
}
