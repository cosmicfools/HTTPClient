//
//  HTTPHeaderRequest.swift
//
//
//  Created by Francisco Javier Trujillo Mata on 6/5/22.
//

import Foundation

private enum Constants {
    static let contentTypeKey = "Content-Type"
    static let authKey = "Authorization"
    static let authType = "Bearer"
    static let multipart = "multipart/form-data"
    static let applicationJson = "application/json"
    static let location = "Location"
    static let contentTypeHeaderValue = "\(Constants.applicationJson); charset=utf-8"
    static let formEncodedHeaderValue = "application/x-www-form-urlencoded"
    static func multipartHeaderValue(boundary: String) -> String { "multipart/form-data; boundary=\(boundary)" }
}

public struct HTTPHeaderRequest {
    public struct KeyValue: Equatable {
        let key: String
        let value: String
    }
    
    var headers: [String: String] { commonHeaders.merging(additionalHeaders) { $1 } }
    
    var applicationJSONTypeHeader: KeyValue {
        KeyValue(key: Constants.contentTypeKey, value: Constants.contentTypeHeaderValue)
    }
    var formEncodedContentTypeHeader: KeyValue {
        KeyValue(key: Constants.contentTypeKey, value: Constants.formEncodedHeaderValue)
    }
    func multipartContentTypeHeader(boundary: String) -> KeyValue {
        KeyValue(key: Constants.contentTypeKey, value: Constants.multipartHeaderValue(boundary: boundary))
    }
    
    public init() {}
}

// MARK: - Private Methods
private extension HTTPHeaderRequest {
    var commonHeaders: [String: String] {
        [
            Constants.contentTypeKey: Constants.contentTypeHeaderValue,
        ]
    }
    
    private var token: [String: String] {
        [:]
    }
    
    private var additionalHeaders: [String: String] {
        [ token ].reduce([:]) { $0.merging($1) { $1 } }
    }
}

struct HTTPHeaderResponse {
    let headers: [AnyHashable: Any]
    
    var needsJSONDecoding: Bool {
        (headers[Constants.contentTypeKey] as? String)?.lowercased().contains(Constants.applicationJson) ?? false
    }
}
