//
//  HTTPService.swift
//
//
//  Created by Francisco Javier Trujillo Mata on 6/5/22.
//

import Foundation

public struct HTTPService {
    public let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
}
