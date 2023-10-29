//
//  RemoteFeedImageLoader.swift
//

import Foundation
import Feedfetcher

public final class RemoteFeedImageLoader: FeedImageDataLoader {
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  private let httpClient: HTTPClient
  
  public init(httpClient: HTTPClient) {
    self.httpClient = httpClient
  }
  
  public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataTask {
    let task = RemoteFeedImageTask(completion: completion)
    task.wrappedHttpTask = httpClient.get(from: url, completion: { [weak self] httpResult in
      guard let self = self else { return }
      
      let result = self.handle(httpResult: httpResult)
      task.complete(with: result)
    })
    return task
  }
  
  private func handle(httpResult: HTTPClient.Result) -> FeedImageDataLoader.Result {
    return httpResult
      .mapError { _ in Error.connectivity }
      .flatMap({ (response, data) in
        let isValidResponse = self.isValid((response, data))
        
        return isValidResponse ? .success(data) : .failure(Error.invalidData)
      })
  }
  
  private func isValid(_ result: (response: HTTPURLResponse, data: Data)) -> Bool {
    let OK_200 = 200
    
    return result.response.statusCode == OK_200 && !result.data.isEmpty
  }
}

// MARK: - RemoteFeedImageTask

private class RemoteFeedImageTask: FeedImageDataTask {
  private var completion: ((RemoteFeedImageLoader.Result) -> Void)?
  var wrappedHttpTask: HTTPClientTask?
  
  init(completion: @escaping (RemoteFeedImageLoader.Result) -> Void) {
    self.completion = completion
  }
  
  func cancel() {
    wrappedHttpTask?.cancel()
    invalidateCompletion()
  }
  
  func complete(with result: RemoteFeedImageLoader.Result) {
    completion?(result)
  }
  
  private func invalidateCompletion() {
    completion = nil
  }
}
