//
//  FeedCache.swift
//

import Foundation

public protocol FeedCache {
  typealias SaveResult = Result<Void, Error>
  
  func save(feed: [FeedImage], completion: @escaping (SaveResult) -> Void)
}
