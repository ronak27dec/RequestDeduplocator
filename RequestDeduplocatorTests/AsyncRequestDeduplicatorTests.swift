//
//  AsyncRequestDeduplicatorTests.swift
//  RequestDeduplocatorTests
//
//  Created by Ronak Malick on 01/02/26.
//

import XCTest
@testable import RequestDeduplocator

final class AsyncRequestDeduplicatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.requestCount = 0
        MockURLProtocol.responseDelay = 0
        MockURLProtocol.handler = nil
    }
    
    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    func testDeduplicatesIdenticalRequests() async throws {
        MockURLProtocol.responseDelay = 300_000_000
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("OK".utf8), response)
        }
        let session = makeMockSession()
        let deduplicator = AsyncRequestDeduplicator(session: session)
        
        let request = URLRequest(url: URL(string: "https://test.com/data")!)
        let endpoint = Endpoint(request: request, deduplicationPolicy: .allow)
        
        async let a = deduplicator.perform(endpoint: endpoint)
        async let b = deduplicator.perform(endpoint: endpoint)
        
        let (data1, data2) = try await (a, b)
        
        XCTAssertEqual(data1, data2)
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testDeduplicatesInFlightRequests() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("OK".utf8), response)
        }
        
        let session = makeMockSession()
        let deduplicator = AsyncRequestDeduplicator(session: session)
        
        let endpoint = Endpoint(
            request: URLRequest(url: URL(string: "https://example.com")!),
            deduplicationPolicy: .allow
        )
        
        async let a = deduplicator.perform(endpoint: endpoint)
        async let b = deduplicator.perform(endpoint: endpoint)
        
        let (r1, r2) = try await (a, b)
        
        XCTAssertEqual(r1, r2)
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testCancellationDoesNotCancelSharedRequest() async throws {
        MockURLProtocol.responseDelay = 200_000_000
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("DATA".utf8), response)
        }
        let session = makeMockSession()
        let deduplicator = AsyncRequestDeduplicator(session: session)
        
        let endpoint = Endpoint(
            request: URLRequest(url: URL(string: "https://test.com/item")!),
            deduplicationPolicy: .allow
        )
        
        let taskA = Task {
            try await deduplicator.perform(endpoint: endpoint)
        }
        
        let taskB = Task {
            try await deduplicator.perform(endpoint: endpoint)
        }
        
        taskA.cancel()
        
        let result = try await taskB.value
        XCTAssertEqual(result, Data("DATA".utf8))
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testPolicyDenyBypassesDeduplicator() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(), response)
        }
        let session = makeMockSession()
        let deduplicator = AsyncRequestDeduplicator(session: session)
        
        let endpoint = Endpoint(
            request: URLRequest(url: URL(string: "https://test.com/write")!),
            deduplicationPolicy: .deny
        )
        
        async let a = deduplicator.perform(endpoint: endpoint)
        async let b = deduplicator.perform(endpoint: endpoint)
        
        _ = try await (a, b)
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }
}
