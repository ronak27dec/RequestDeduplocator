//
//  MockURLProtocol.swift
//  RequestDeduplocatorTests
//
//  Created by Ronak Malick on 01/02/26.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    static var requestCount = 0
    static var responseDelay: UInt64 = 0
    static var handler: ((URLRequest) throws -> (Data, URLResponse))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        Self.requestCount += 1
        
        Task {
            if Self.responseDelay > 0 {
                try await Task.sleep(nanoseconds: Self.responseDelay)
            }
            
            guard let handler = Self.handler else {
                fatalError("Handler not set")
            }
            
            do {
                let (data, response) = try handler(request)
                
                client?.urlProtocol(self,
                                    didReceive: response,
                                    cacheStoragePolicy: .notAllowed)
                
                client?.urlProtocol(self, didLoad: data)
                
                client?.urlProtocolDidFinishLoading(self)
                
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    override func stopLoading() {
        // Called if the task is cancelled
    }
}
