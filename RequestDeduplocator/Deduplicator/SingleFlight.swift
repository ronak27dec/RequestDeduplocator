//
//  SingleFlight.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 02/02/26.
//

import Foundation

/*
 This gives you a concurrency-safe “execute-once-at-a-time” guarantee.
*/
actor SingleFlight {
    private var inFlight: Bool = false
    
    func run(_ work: @escaping() async -> (Void)) async {
        guard inFlight == false else { return }
        inFlight = true
        defer { inFlight = false }
        await work()
    }
    
}
