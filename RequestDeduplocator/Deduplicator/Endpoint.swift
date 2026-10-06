//
//  Endpoint.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

struct Endpoint {
    let request: URLRequest
    let deduplicationPolicy: DeduplicationPolicy
}
