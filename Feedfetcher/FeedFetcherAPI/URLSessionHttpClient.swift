//
//  URLSessionHttpClient.swift
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
  private let session: URLSession
  
  public init(session: URLSession = .shared) {
    self.session = session
  }
  
  struct UnexpectedValuesError: Error { }
  
  public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
    let task = URLSessionTask()
    task.wrappedTask = session.dataTask(with: url) { (data, response, error) in
      completion(Result(catching: {
        if let error = error {
          throw error
        }
        guard let data = data,
              let response =  response as? HTTPURLResponse
        else {
          throw UnexpectedValuesError()
        }
        return (response, data)
      }))
    }
    task.wrappedTask?.resume()
    return task
  }
}

private class URLSessionTask: HTTPClientTask {
  var wrappedTask: URLSessionDataTask?
  
  func cancel() {
    wrappedTask?.cancel()
  }
}
