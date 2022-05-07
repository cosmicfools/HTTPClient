//
//  HTTPClient.swift
//
//
//  Created by Francisco Javier Trujillo Mata on 6/5/22.
//

import Foundation

public struct HTTPClient {
    enum Method: String {
        case DELETE
        case GET
        case POST
        case PUT
    }
    
    public enum ContentType {
        case applicationJson
        case formURLEnconded
        case multipart
    }
    
    private let baseURL: URL
    private let requestEnconding: HTTPRequestEncoding
    private let headersRequest: HTTPHeaderRequest
    
    public init(baseURL: URL,
         requestEnconding: HTTPRequestEncoding = HTTPRequestEncoding(),
         headersRequest: HTTPHeaderRequest = HTTPHeaderRequest()) {
        self.baseURL = baseURL
        self.requestEnconding = requestEnconding
        self.headersRequest = headersRequest
    }
    
    public func get<Tparam: Encodable, Tresponse: Decodable>(
        path: String,
        parameters: Tparam?,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        makeRequest(path: path, parameters: parameters, method: get, completionHandler: completionHandler)
    }
    
    public func get<Tresponse: Decodable>(
        path: String,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        makeRequest(path: path, parameters: APIEmptyRequestResponse(), method: get, completionHandler: completionHandler)
    }

    
    public func get<Tresponse: Decodable>(
        url: URL,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = Method.GET.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        
        makeRequest(request: request, parameters: APIEmptyRequestResponse(), method: get, completionHandler: completionHandler)
    }
    
    public func post<Tparam: Encodable, Tresponse: Decodable>(
        path: String,
        parameters: Tparam?,
        contentType: ContentType = .applicationJson,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        makeRequest(path: path, parameters: parameters, method: post,
                    contentType: contentType, completionHandler: completionHandler)
    }
    
    public func post<Tparam: Encodable, Tresponse: Decodable>(
        url: URL,
        parameters: Tparam?,
        contentType: ContentType = .applicationJson,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = Method.POST.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        
        makeRequest(request: request, parameters: parameters, method: post, completionHandler: completionHandler)
    }
    
    public func put<Tparam: Encodable, Tresponse: Decodable>(
        path: String,
        parameters: Tparam?,
        contentType: ContentType = .applicationJson,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        makeRequest(path: path, parameters: parameters, method: put,
                    contentType: contentType, completionHandler: completionHandler)
    }
    
    public func delete<Tparam: Encodable, Tresponse: Decodable>(
        path: String,
        parameters: Tparam?,
        contentType: ContentType = .applicationJson,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
        makeRequest(path: path, parameters: parameters, method: delete,
                    contentType: contentType, completionHandler: completionHandler)
    }
}

// MARK: - Private Methods
private extension HTTPClient {
    var sessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = headersRequest.headers
        
        return configuration
    }
    
    func makeRequest<Tparam: Encodable, Tresponse: Decodable>(
        request: URLRequest? = nil,
        path: String = "/",
        parameters: Tparam?,
        method: (URL, Tparam?, ContentType) -> URLRequest,
        contentType: ContentType = .applicationJson,
        completionHandler: @escaping (_ result: Result<Tresponse, Error>) -> Void) {
            guard let url = URL(string: path, relativeTo: baseURL) else { return }
        let session = URLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: nil)
        let request = request ?? method(url, parameters, contentType)
        let handler = requestCompletionHandler(completionHandler)
        let task = session.dataTask(with: request, completionHandler: handler)
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func get<T: Encodable>(url: URL, parameters: T?, contentType: ContentType) -> URLRequest {
        var fullURL = url
        let urlComponents = getUrlComponents(url: url, parameters: parameters)
        if let absoluteURL = urlComponents?.url {
            fullURL = absoluteURL
        }
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = Method.GET.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        
        return request
    }
    
    func post<T: Encodable>(url: URL, requestBody: T?, contentType: ContentType) -> URLRequest {
        let requestInfo = requestEnconding.requestContent(contentType: contentType, parameters: requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = Method.POST.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        request.setValue(requestInfo.header.value, forHTTPHeaderField: requestInfo.header.key)
        request.httpBody = requestInfo.body

        return request
    }
    
    func put<T: Encodable>(url: URL, requestBody: T?, contentType: ContentType) -> URLRequest {
        let requestInfo = requestEnconding.requestContent(contentType: contentType, parameters: requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = Method.PUT.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        request.setValue(requestInfo.header.value, forHTTPHeaderField: requestInfo.header.key)
        request.httpBody = requestInfo.body

        return request
    }
    
    func delete<T: Encodable>(url: URL, requestBody: T?, contentType: ContentType) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = Method.DELETE.rawValue
        request.allHTTPHeaderFields = headersRequest.headers
        
        if let httpBody = try? JSONEncoder().encode(requestBody) {
            request.httpBody = httpBody
        }

        return request
    }
    
    func getUrlComponents<T: Encodable>(url: URL, parameters: T?) -> URLComponents? {
        guard let json = try? JSONEncoder().encode(parameters),
            let dict = try? JSONSerialization.jsonObject(with: json, options: .mutableLeaves) as? [String: Any],
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        
        urlComponents.queryItems = dict.flatMap({ key, value -> [URLQueryItem] in
            if let valueArray = value as? [String] {
                return valueArray.map { URLQueryItem(name: key, value: $0) }
            } else {
                return [URLQueryItem(name: key, value: "\(value)")]
            }
        })
        
        return urlComponents
    }
    
    func requestCompletionHandler<T: Decodable>(_ completionHandler: @escaping (_ result: Result<T, Error>) -> Void)
        -> (Data?, URLResponse?, Error?) -> Void {
            let completion: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
                switch (response, error) {
                case (.some(let response), _): completionHandler(self.handleSuccessResponse(data: data, response: response))
                case (_, .some(let error)): completionHandler(.failure(error))
                default: completionHandler(.failure(NSError()))
                }
            }
            return completion
    }
    
    func handleSuccessResponse<T: Decodable>(data: Data?, response: URLResponse?) -> Result<T, Error> {
         if let data = data, let response = response as? HTTPURLResponse,
         HTTPHeaderResponse(headers: response.allHeaderFields).needsJSONDecoding {
             // We check if the response is a JSON
             do {
                 let responseObject = try JSONDecoder().decode(T.self, from: data)
                 return .success(responseObject)
             } catch {
                 print(error)
                 return .failure(error)
             }
         } else if let data = data as? T {
             return .success(data)
         } else if let data = data, let string = String(data: data, encoding: .utf8) as? T {
            return .success(string)
         } else {
            let domain = "Decode error in \(String(describing: response?.url))"
            return .failure(NSError(domain: domain, code: .zero, userInfo: nil))
         }
    }
}
