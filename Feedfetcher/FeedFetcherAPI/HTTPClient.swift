//
//  HTTPClient.swift
//

import Foundation

public protocol HTTPClientTask {
  func cancel()
}

public protocol HTTPClient {
  typealias Result = Swift.Result<(response: HTTPURLResponse, data: Data), Error>
  
  @discardableResult
  func get(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask
}
