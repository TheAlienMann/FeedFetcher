//
//  FeedImageDataLoader.swift
//

import Foundation

public protocol FeedImageDataTask {
  func cancel()
}

public protocol FeedImageDataLoader {
  typealias Result = Swift.Result<Data, Error>
  
  func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataTask
}
