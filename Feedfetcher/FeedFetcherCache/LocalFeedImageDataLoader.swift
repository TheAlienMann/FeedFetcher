//
//  LocalFeedImageDataLoader.swift
//

import Foundation
import Feedfetcher

public final class LocalFeedImageDataLoader {
  private let store: FeedImageDataStore
  
  public init(store: FeedImageDataStore) {
    self.store = store
  }
}

// MARK: - LoadImageData

extension LocalFeedImageDataLoader: FeedImageDataLoader {
  public enum LoadError: Swift.Error {
    case failed
    case notFound
  }
  
  public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataTask {
    let task = ImageDataLoadTask(completion: completion)
    
    store.retrieveImageData(for: url, completion: { [weak self] retrieveResult in
      guard let self = self else { return }
      
      let loadResult = self.handle(storeRetrieveResult: retrieveResult)
      task.complete(with: loadResult)
    })
    
    return task
  }
  
  private func handle(storeRetrieveResult retrieveResult: FeedImageDataStore.RetrieveResult) -> FeedImageDataLoader.Result {
    return retrieveResult
      .mapError { _ in LoadError.failed }
      .flatMap { data in
        if let data = data {
          return .success(data)
        } else {
          return .failure(LoadError.notFound)
        }
      }
  }
  
  // MARK: - ImageDataLoadTask
  
  private class ImageDataLoadTask: FeedImageDataTask {
    private var completion: ((LocalFeedImageDataLoader.Result) -> Void)?
    
    init(completion: @escaping (LocalFeedImageDataLoader.Result) -> Void) {
      self.completion = completion
    }
    
    func cancel() {
      invalidateCompletion()
    }
    
    func complete(with result: LocalFeedImageDataLoader.Result) {
      completion?(result)
    }
    
    private func invalidateCompletion() {
      completion = nil
    }
  }
}

// MARK: - saveImageData

extension LocalFeedImageDataLoader: FeedImageDataCache {
  public typealias SaveResult = FeedImageDataCache.SaveResult
  
  public enum SaveError: Swift.Error {
    case failed
  }
  
  public func saveImageData(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
    store.insertImageData(data, for: url, completion: { [weak self] insertResult in
      if self == nil { return }
      
      let result: SaveResult = insertResult.mapError { _ in SaveError.failed }
      
      completion(result)
    })
  }
}
