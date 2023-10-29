//
//  HTTPClientSpy.swift
//

import Foundation
import Feedfetcher
import FeedFetcherAPI

class HTTPClientSpy: HTTPClient {
  typealias Completion = (HTTPClient.Result) -> Void
  private var messages = [(requestedURL: URL, completion: Completion)]()
  private(set) var cancelledRequests = [URL]()
  
  var requestedURLs: [URL] {
    messages.map { $0.requestedURL }
  }
  
  func get(from url: URL, completion: @escaping Completion) -> HTTPClientTask {
    messages.append((url, completion))
    
    return HTTPClientSpyTask { [weak self] in
      self?.cancelledRequests.append(url)
    }
  }
  
  func complete(withError error: Error, at index: Int = 0) {
    messages[index].completion(.failure(error))
  }
  
  func complete(withStatusCode status: Int, data: Data = Data(), at index: Int = 0) {
    guard let response = HTTPURLResponse(url: requestedURLs[index], statusCode: status, httpVersion: nil, headerFields: nil) else {
      return
    }
    messages[index].completion(.success((response, data)))
  }
}

private struct HTTPClientSpyTask: HTTPClientTask {
  var callback: () -> Void
  
  func cancel() {
    callback()
  }
}
