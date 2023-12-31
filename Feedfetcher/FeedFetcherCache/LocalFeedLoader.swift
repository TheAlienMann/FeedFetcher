//
//  LocalFeedLoader.swift
//

import Foundation
import Feedfetcher

final public class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date
  
  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
}

extension LocalFeedLoader: FeedCache {
  public typealias SaveResult = FeedCache.SaveResult
  
  public func save(feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
    store.deleteCachedFeed(completion: { [weak self] deletionResult in
      guard let self = self else { return }
      switch deletionResult {
        case .success:
          self.cache(feed: feed, with: completion)
        case let .failure(cachedDeletionError):
          completion(.failure(cachedDeletionError))
      }
    })
  }
  
  private func cache(feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
    store.insert(feed.mapToLocal(), timestamp: currentDate(), completion: { [weak self] insertionResult in
      guard self != nil else { return }
      switch insertionResult {
        case .success:
          completion(.success(()))
        case let .failure(error):
          completion(.failure(error))
      }
    })
  }
}

extension LocalFeedLoader: FeedLoader {
  public func load(completion: @escaping (FeedLoader.Result) -> Void) {
    store.retrieveCachedFeed(completion: { [weak self] result in
      guard let self = self else { return }
      switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(.some(cache)) where FeedCachePolicy.validate(cache.timestamp, against: self.currentDate()):
          completion(.success(cache.feed.mapToModel()))
        case .success:
          completion(.success([]))
      }
    })
  }
}

extension LocalFeedLoader {
  public typealias ValidateResult = Result<Void, Error>
  
  public func validateCache(completion: @escaping (ValidateResult) -> Void) {
    store.retrieveCachedFeed(completion: { [weak self] result in
      guard let self = self else { return }
      switch result {
        case .failure:
          self.store.deleteCachedFeed(completion: completion)
        case let .success(.some(cache)) where !FeedCachePolicy.validate(cache.timestamp, against: self.currentDate()):
          self.store.deleteCachedFeed(completion: completion)
        case .success:
          completion(.success(()))
      }
    })
  }
}

private extension Array where Element == FeedImage {
  func mapToLocal() -> [LocalFeedImage] {
    self.map {
      LocalFeedImage(
        id: $0.id,
        url: $0.url,
        description: $0.description,
        location: $0.location)
    }
  }
}

private extension Array where Element == LocalFeedImage {
  func mapToModel() -> [FeedImage] {
    self.map {
      FeedImage(
        id: $0.id,
        url: $0.url,
        description: $0.description,
        location: $0.location)
    }
  }
}
