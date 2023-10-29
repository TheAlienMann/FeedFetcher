//
//  RemoteFeedLoaderTests.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherAPI

class RemoteFeedLoaderTests: XCTestCase {
  func test_initWithClient_load_noRequestsDataFromURL() {
    let (_, httpClient) = makeSUT()
    
    XCTAssertTrue(httpClient.requestedURLs.isEmpty)
  }
  
  func test_initWithClient_load_requestsDataFromURL() {
    let url = anyURL()
    let (loader, httpClient) = makeSUT(url: url)
    
    loader.load(completion: { _ in })
    
    XCTAssertEqual(httpClient.requestedURLs, [url])
  }
  
  func test_initWithClient_loadTwice_requestsDataTwiceFromURL() {
    let url = anyURL()
    let (loader, httpClient) = makeSUT(url: url)
    
    loader.load(completion: { _ in })
    loader.load(completion: { _ in })
    
    XCTAssertEqual(httpClient.requestedURLs, [url, url])
  }
  
  func test_clientError_load_returnsConnectivityError() {
    let (loader, client) = makeSUT()
    
    executeAndAssert(forSUT: loader, expected: failure(.connectivity), when: {
      let clientError = anyNSError()
      client.complete(withError: clientError)
    })
  }
  
  func test_httpResponseIsNot200_load_returnsInvalidDataError() {
    let (loader, client) = makeSUT()
    let statusCodes = [199, 201, 400, 900]
    
    statusCodes.enumerated().forEach { index, code in
      executeAndAssert(forSUT: loader, expected: failure(.invalidData), when: {
        client.complete(withStatusCode: code, at: index)
      })
    }
  }
  
  func test_200HttpStatusCodeAndInvalidJSON_load_returnsInvalidDataError() {
    let (loader, client) = makeSUT()
    
    executeAndAssert(forSUT: loader, expected: failure(.invalidData), when: {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }
  
  func test_200HttpStatusCodeAndEmptyListJSON_load_returnsEmptyFeedItemsArray() {
    let (loader, client) = makeSUT()
    
    executeAndAssert(forSUT: loader, expected: .success([FeedImage]()), when: {
      let emptyListJSON = Data("{ \"items\": [] }".utf8)
      client.complete(withStatusCode: 200, data: emptyListJSON)
    })
  }
  
  func test_200HttpStatusCodeAndItemsListJSON_load_returnsFeedItemsArray() {
    let item = makeFeedItem(id: UUID(), url: anyURL())
    let itemWithDescription = makeFeedItem(id: UUID(), url: anyURL(), description: "a description")
    let itemWithLocation = makeFeedItem(id: UUID(), url: anyURL(), location: "a location")
    
    let feedItems = [item.model, itemWithDescription.model, itemWithLocation.model]
    let feedItemsJSON = ["items": [item.json, itemWithDescription.json, itemWithLocation.json]]
    
    let (loader, client) = makeSUT()
    
    executeAndAssert(forSUT: loader, expected: .success(feedItems), when: {
      let json = try! JSONSerialization.data(withJSONObject: feedItemsJSON)
      client.complete(withStatusCode: 200, data: json)
    })
  }
  
  func test_sutHasBeenDeallocated_load_noResponseShouldBeReceived() {
    let url = anyURL()
    let client = HTTPClientSpy()
    var sut: RemoteFeedLoader? = RemoteFeedLoader(from: url, httClient: client)
    
    var receivedResults: RemoteFeedLoader.Result?
    sut?.load(completion: {
      receivedResults = $0
    })
    
    sut = nil
    client.complete(withStatusCode: 200, data: Data("{ \"items\": [] }".utf8))
    
    XCTAssertNil(receivedResults, "No result should be received if RemoteLoader has been deallocated.")
  }
  
  // MARK: - Helpers
  
  private func makeSUT(url: URL = anyURL(), file: StaticString = #file, line: UInt = #line) -> (loader: RemoteFeedLoader, httpClient: HTTPClientSpy) {
    let httpClient = HTTPClientSpy()
    let sut = RemoteFeedLoader(from: url, httClient: httpClient)
    
    trackForMemoryLeak(httpClient, file: file, line: line)
    trackForMemoryLeak(sut, file: file, line: line)
    
    return (sut, httpClient)
  }
  
  func makeFeedItem(id: UUID, url: URL, description: String? = nil, location: String? = nil) -> (model: FeedImage, json: [String: Any]) {
    let feedItem = FeedImage(id: id, url: url, description: description, location: location)
    let json = [
      "id": id.uuidString,
      "image": url.absoluteString,
      "description": description,
      "location": location
    ].compactMapValues { $0 }
    
    return (feedItem, json)
  }
  
  func failure(_ error: RemoteFeedLoader.Error) -> FeedLoader.Result {
    return .failure(error)
  }
  
  func executeAndAssert(forSUT loader: RemoteFeedLoader, expected: FeedLoader.Result, file: StaticString = #file, line: UInt = #line, when action: () -> Void) {
    let exp = expectation(description: "Wait for load completion.")
    
    loader.load(completion: { receivedResult in
      switch (receivedResult, expected) {
        case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
          XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        case let (.success(receivedItems), .success(expectedItems)):
          XCTAssertEqual(receivedItems, expectedItems)
        default:
          XCTFail("Expected result \(expected) but got \(receivedResult) instead.", file: file, line: line)
      }
      exp.fulfill()
    })
    action()
    wait(for: [exp], timeout: 1.0)
  }
}
