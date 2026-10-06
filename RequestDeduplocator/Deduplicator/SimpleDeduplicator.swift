//
//  SimpleDeduplicator.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

actor SimpleDeduplicator {
    static let shared = SimpleDeduplicator()
    private var activeTasks: [String: Task<Data, Error>] = [:]
    
    func fetch<T: Decodable>(
        url: URL,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let key = url.absoluteString
        
        if let existingTask = activeTasks[key] {
            return try await existingTask.value as! T
        }
        
        let task = Task<Data, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        activeTasks[key] = task
        
        do {
            let data = try await task.value
            activeTasks.removeValue(forKey: key)
            return try decoder.decode(T.self, from: data)
        } catch {
            activeTasks.removeValue(forKey: key)
            throw error
        }
    }
    
    func cancel(url: URL) {
        let key = url.absoluteString
        activeTasks[key]?.cancel()
        activeTasks.removeValue(forKey: key)
    }
}
