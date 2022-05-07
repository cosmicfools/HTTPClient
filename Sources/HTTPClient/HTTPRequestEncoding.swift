//
//  HTTPRequestEncoding.swift
//
//
//  Created by Francisco Javier Trujillo Mata on 6/5/22.
//

import Foundation

public struct HTTPRequestEncoding {
    public init() { }
    
    public func requestContent<T: Encodable>(contentType: HTTPClient.ContentType,
                                      parameters: T ) -> (header: HTTPHeaderRequest.KeyValue, body: Data?) {
        let headerKey: HTTPHeaderRequest.KeyValue
        let body: Data?
        switch contentType {
        case .applicationJson:
            headerKey = HTTPHeaderRequest().applicationJSONTypeHeader
            body = applicationJson(parameters: parameters)
        case .formURLEnconded:
            headerKey = HTTPHeaderRequest().formEncodedContentTypeHeader
            body = formURLData(parameters: parameters)
        case .multipart:
            let boundary = UUID().uuidString
            headerKey = HTTPHeaderRequest().multipartContentTypeHeader(boundary: boundary)
            body = multipart(boundary: boundary, parameters: parameters)
        }
        
        return (header: headerKey, body: body)
    }
    
    private func applicationJson<T: Encodable>(parameters: T) -> Data? { try? JSONEncoder().encode(parameters) }
    
    private func formURLData<T: Encodable>(parameters: T) -> Data? {
    guard let json = try? JSONEncoder().encode(parameters),
        let dict = try? JSONSerialization.jsonObject(with: json, options: .mutableLeaves) as? [String: Any]
        else { return nil }
    
    var urlComponents = URLComponents()
    urlComponents.queryItems = dict.flatMap({ key, value -> [URLQueryItem] in
        if let valueArray = value as? [String] {
            return valueArray.map { URLQueryItem(name: key, value: $0) }
        } else {
           return [URLQueryItem(name: key, value: "\(value)")]
        }
    })

        return urlComponents.query?.data(using: .utf8)
    }
    
    private func multipart<T: Encodable>(boundary: String, parameters: T) -> Data? {
        guard let json = try? JSONEncoder().encode(parameters),
        let dict = try? JSONSerialization.jsonObject(with: json, options: .mutableLeaves) as? [String: Any]
        else { return nil }
        
        // Add the image data to the raw http request data
        var dataBody: Data = dict.reduce(into: Data()) { body, keyValue in
            guard let stringValue = keyValue.value as? String, let value = Data(base64Encoded: stringValue),
                let starting = ("\r\n--\(boundary)\r\n" +
                    "Content-Disposition: form-data; name=\"\(keyValue.key)\"; filename=\"\(keyValue.key).png\"\r\n" +
                    "Content-Type: image/png\r\n\r\n").data(using: .utf8),
                let ending = "\r\n".data(using: .utf8) else { return }
            body.append(starting)
            body.append(value)
            body.append(ending)
        }
        dataBody.append("--\(boundary)--".data(using: .utf8)!)
        
        return dataBody
    }
}
