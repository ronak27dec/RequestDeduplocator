//
//  RequestKey.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

struct RequestKey: Hashable, Sendable {
    let method: String
    let url: URL
    let headerHash: Int
    let bodyHash: Int
    
    static func from(_ endpoint: Endpoint) -> RequestKey? {
        guard let url = endpoint.request.url else { return nil }
        let headers = endpoint.request.allHTTPHeaderFields ?? [:]
        
        let filteredHeaders = headers.filter{ $0.key.lowercased() != "authorization" }
        
        let headerHash = filteredHeaders
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined()
            .hashValue
        
        let bodyHash = endpoint.request.httpBody?.hashValue ?? 0
        
        return RequestKey(method: endpoint.request.httpMethod ?? "GET",
                          url: url,
                          headerHash: headerHash,
                          bodyHash: bodyHash)
    }
}
