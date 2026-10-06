//
//  AsyncRequestDeduplicator.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

actor AsyncRequestDeduplicator {
    static let shared = AsyncRequestDeduplicator()
    
    private var inFlight: [RequestKey: InFlightAsyncRequest] = [:]
    private let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func perform(endpoint: Endpoint) async throws -> Data {
        guard endpoint.deduplicationPolicy == .allow,
              let key = RequestKey.from(endpoint) else {
            return try await execute(request: endpoint.request)
        }
        
        if let inFlightRequest = inFlight[key] {
            inFlightRequest.addSubscriber()
            return try await awaitResult(for: inFlightRequest, key: key)
        }
        
        let task = Task<Data, Error> {[session] in
            let (data, _) = try await session.data(for: endpoint.request)
            return data
        }
        
        let inFlightRequest = InFlightAsyncRequest(task: task)
        inFlight[key] = inFlightRequest
        
        return try await awaitResult(
            for: inFlightRequest,
            key: key
        )
    }
    
    private func execute(request: URLRequest) async throws -> Data {
        let (data, _) = try await session.data(for: request)
        return data
    }
    
    private func awaitResult(for request: InFlightAsyncRequest,
                             key: RequestKey) async throws -> Data {
        do {
            let result = try await request.task.value
            await removeSubscriber(request, key: key)
            return result
        } catch {
            await removeSubscriber(request, key: key)
            throw error
        }
    }
    
    private func removeSubscriber(_ request: InFlightAsyncRequest,
                                  key: RequestKey) async {
        let shouldCancel = await request.removeSubscriber()
        if shouldCancel {
            await request.task.cancel()
            inFlight[key] = nil
        }
    }
}
