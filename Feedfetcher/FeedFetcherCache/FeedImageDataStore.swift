//
//  FeedImageDataStore.swift
//

import Foundation

public protocol FeedImageDataStore {
  typealias RetrieveResult = Swift.Result<Data?, Error>
  typealias InsertResult = Swift.Result<Void, Error>
  
  func retrieveImageData(for url: URL, completion: @escaping (RetrieveResult) -> Void)
  func insertImageData(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void)
}
