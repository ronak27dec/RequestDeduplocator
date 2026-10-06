//
//  InFlightAsyncRequest.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

final class InFlightAsyncRequest {
    private(set) var task: Task<Data, Error>
    private(set) var subscribers: Int
    
    init(task: Task<Data, Error>) {
        self.task = task
        self.subscribers = 1
    }
    
    func addSubscriber() {
        subscribers += 1
    }
    
    func removeSubscriber() -> Bool {
        guard subscribers > 0 else { return false }
        subscribers -= 1
        return subscribers == 0
    }
}
