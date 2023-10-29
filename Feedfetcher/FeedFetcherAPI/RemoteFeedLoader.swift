//
//  RemoteFeedLoader.swift
//

import Foundation
import Feedfetcher

public final class RemoteFeedLoader: FeedLoader {
  private let client: HTTPClient
  private let url: URL
  
  public enum Error: Swift.Error {
    public typealias RawValue = String
    
    case connectivity
    case invalidData
  }
  
  public init(from url: URL, httClient client: HTTPClient) {
    self.client = client
    self.url = url
  }
  
  public func load(completion: @escaping (FeedLoader.Result) -> Void) {
    client.get(from: url, completion: { [weak self] result in
      guard let self = self else { return }
      
      switch result {
        case let .success((response, data)):
          let result = self.map(response: response, data: data)
          completion(result)
        case .failure:
          completion(.failure(Error.connectivity))
      }
    })
  }
  
  private func map(response: HTTPURLResponse, data: Data) -> FeedLoader.Result {
    do {
      let remoteItems = try FeedItemsMapper.map(data: data, from: response)
      return .success(remoteItems.mapToItems())
    } catch {
      return .failure(error)
    }
  }
}

private extension Array where Element == RemoteFeedItem {
  func mapToItems() -> [FeedImage] {
    return self.map {
      FeedImage(
        id: $0.id,
        url: $0.image,
        description: $0.description,
        location: $0.location)
    }
  }
}
