//
//  RemoteFeedImageLoaderTests.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherAPI

class RemoteFeedImageLoaderTests: XCTestCase {
  func test_init_doesNotRequestData() {
    let (_, httpClient) = makeSUT()
    
    XCTAssertEqual(httpClient.requestedURLs, [])
  }
  
  func test_loadImageData_requestDataFromURL() {
    let url = anyURL()
    let (sut, httpClient) = makeSUT()
    
    _ = sut.loadImageData(from: url, completion: { _ in })
    
    XCTAssertEqual(httpClient.requestedURLs, [url])
  }
  
  func test_loadImageDataTwice_requestDataFromURLTwice() {
    let url = anyURL()
    let (sut, httpClient) = makeSUT()
    
    _ = sut.loadImageData(from: url, completion: { _ in })
    _ = sut.loadImageData(from: url, completion: { _ in })
    
    XCTAssertEqual(httpClient.requestedURLs, [url, url])
  }
  
  func test_loadImageData_respondsWithConnectivityErrorOnClientError() {
    let (sut, httpClient) = makeSUT()
    
    expect(sut, toCompleteWith: failure(.connectivity), when: {
      httpClient.complete(withError: anyNSError())
    })
  }
  
  func test_loadImageData_respondsInvalidDataErrorOnNon200HTTPResponse() {
    let (sut, httpClient) = makeSUT()
    let samples = [199, 201, 400, 500]
    
    samples.enumerated().forEach { index, statusCode in
      expect(sut, toCompleteWith: failure(.invalidData), when: {
        httpClient.complete(withStatusCode: statusCode, at: index)
      })
    }
  }
  
  func test_loadImageData_respondsInvalidDataErrorOn200HTTPResponseWithEmptyData() {
    let (sut, httpClient) = makeSUT()
    let emptyData = Data()
    
    expect(sut, toCompleteWith: failure(.invalidData), when: {
      httpClient.complete(withStatusCode: 200, data: emptyData)
    })
  }
  
  func test_loadImageData_respondsWithDataOn200HTTPResponseWithNonEmptyData() {
    let (sut, httpClient) = makeSUT()
    let nonEmptyData = anyData()
    
    expect(sut, toCompleteWith: .success(nonEmptyData), when: {
      httpClient.complete(withStatusCode: 200, data: nonEmptyData)
    })
  }
  
  func test_loadImageData_doesNotCompleteAfterLoaderDeallocated() {
    let httpClient = HTTPClientSpy()
    var sut: RemoteFeedImageLoader? = RemoteFeedImageLoader(httpClient: httpClient)
    
    _ = sut?.loadImageData(from: anyURL(), completion: { result in
      XCTFail("Load image should not complete after loader has been deallocated.")
    })
    
    sut = nil
    httpClient.complete(withStatusCode: 200)
  }
  
  func test_cancelLoadImageDataTask_cancelClientRequest() {
    let (sut, httpClient) = makeSUT()
    let url = anyURL()
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    XCTAssertTrue(httpClient.cancelledRequests.isEmpty, "Expected no cancelled url request before task is cancelled.")
    
    task.cancel()
    XCTAssertEqual(httpClient.cancelledRequests, [url], "Expected cancelled url request after ask is cancelled.")
  }
  
  func test_loadImageData_doesNotCompleteAfterCancellingTask() {
    let (sut, httpClient) = makeSUT()
    let url = anyURL()
    
    let task = sut.loadImageData(from: url, completion: { result in
      XCTFail("Expected load to not complete as the task was cancelled.")
    })
    
    task.cancel()
    httpClient.complete(withError: anyNSError())
    httpClient.complete(withStatusCode: 404, data: anyData())
    httpClient.complete(withStatusCode: 200, data: anyData())
  }
  
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedImageLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedImageLoader(httpClient: client)
    
    trackForMemoryLeak(sut, file: file, line: line)
    trackForMemoryLeak(client, file: file, line: line)
    
    return (sut, client)
  }
  
  private func expect(_ sut: RemoteFeedImageLoader, toCompleteWith expected: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Waiting for image load to complete.")
    
    _ = sut.loadImageData(from: anyURL(), completion: { result in
      switch (expected, result) {
        case let (.failure(expectedError as RemoteFeedImageLoader.Error), .failure(receivedError as RemoteFeedImageLoader.Error)):
          XCTAssertEqual(expectedError, receivedError, "Expected \(expectedError) but got \(receivedError)", file: file, line: line)
        case let (.success(expectedData), .success(receivedData)):
          XCTAssertEqual(expectedData, receivedData, "Expected to receive data \(expectedData) but got \(receivedData)", file: file, line: line)
        default:
          XCTFail("Expected \(expected) but got \(result) instead.", file: file, line: line)
      }
      exp.fulfill()
    })
    
    action()
    
    wait(for: [exp], timeout: 1.0)
  }
  
  private func failure(_ error: RemoteFeedImageLoader.Error) -> RemoteFeedImageLoader.Result {
    return .failure(error)
  }
}
