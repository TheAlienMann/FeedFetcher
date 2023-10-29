//
//  FeedImageDataCache.swift
//

import Foundation

public protocol FeedImageDataCache {
  typealias SaveResult = Swift.Result<Void, Error>
  
  func saveImageData(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}
