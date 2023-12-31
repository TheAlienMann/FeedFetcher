//
//  LoadFeedImageDataFromCacheUseCaseTests.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherCache

class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
  func test_feedImageDataStore_doesNotRequestDataAtInit() {
    let (_, store) = makeSUT()
    
    XCTAssertEqual(store.messages, [])
  }
  
  func test_loadImageData_requestsRetrievalToStore() {
    let (sut, store) = makeSUT()
    let aURL = anyURL()
    
    let _ = sut.loadImageData(from: aURL, completion: { _ in })
    
    XCTAssertEqual(store.messages, [.retrieveImageData(aURL)])
  }
  
  func test_loadImageDataTwice_requestsRetrievalToStoreTwice() {
    let (sut, store) = makeSUT()
    let aURL = anyURL()
    let otherURL = URL(string: "http://other-url.com")!
    
    let _ = sut.loadImageData(from: aURL, completion: { _ in })
    let _ = sut.loadImageData(from: otherURL, completion: { _ in })
    
    XCTAssertEqual(store.messages, [.retrieveImageData(aURL), .retrieveImageData(otherURL)])
  }
  
  func test_loadImageData_completesWithFailedErrorOnStoreFailure() {
    let (sut, store) = makeSUT()
    
    loadImageData(sut, andExpect: failure(.failed), when: {
      store.completeRetrievalWithError()
    })
  }
  
  func test_loadImageData_completesWithNotFoundErrorNotFound() {
    let (sut, store) = makeSUT()
    
    loadImageData(sut, andExpect: failure(.notFound), when: {
      store.completeRetrievalWith(data: nil)
    })
  }
  
  func test_loadImageData_completesWithDataOnFoundData() {
    let (sut, store) = makeSUT()
    let foundData = anyData()
    
    loadImageData(sut, andExpect: .success(foundData), when: {
      store.completeRetrievalWith(data: foundData)
    })
  }
  
  func test_loadImageData_completesWithEmptyDataOnFoundEmptyDataOnFoundEmptyData() {
    let (sut, store) = makeSUT()
    let emptyData = Data()
    
    loadImageData(sut, andExpect: .success(emptyData), when: {
      store.completeRetrievalWith(data: emptyData)
    })
  }
  
  func test_loadImageData_doesNotCompleteAfterLoaderIsDeallocated() {
    let store = FeedImageDataStoreSpy()
    var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)
    
    let _ = sut?.loadImageData(from: anyURL(), completion: {_ in
      XCTFail("Expected load to not complete after the sut has been deallocated.")
    })
    
    sut = nil
    store.completeRetrievalWithEmptyCache()
  }
  
  func test_loadImageData_doesNotCompleteAfterTaskCancellation() {
    let (sut, loader) = makeSUT()
    
    let task = sut.loadImageData(from: anyURL(), completion: { _ in
      XCTFail("Expected load to not complete after task cancellation.")
    })
    
    task.cancel()
    loader.completeRetrievalWithError()
  }
  
  
  
  
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
    let store = FeedImageDataStoreSpy()
    let sut = LocalFeedImageDataLoader(store: store)
    
    trackForMemoryLeak(store, file: file, line: line)
    trackForMemoryLeak(sut, file: file, line: line)
    
    return (sut, store)
  }
  
  func loadImageData(_ sut: LocalFeedImageDataLoader, andExpect expected: LocalFeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Waiting for load image data to complete.")
    
    let _ = sut.loadImageData(from: anyURL(), completion: { result in
      switch (expected, result) {
        case let (.failure(expectedError as LocalFeedImageDataLoader.LoadError), .failure(resultError as LocalFeedImageDataLoader.LoadError)):
          XCTAssertEqual(expectedError, resultError, "Expected failure result with error \(expectedError) but got \(resultError) instead.", file: file, line: line)
        case let (.success(expectedData), .success(resultData)):
          XCTAssertEqual(expectedData, resultData, "Expected success result with data \(expectedData) but got \(resultData) instead.", file: file, line: line)
        default:
          XCTFail("Expected \(expected) but got \(result) instead.", file: file, line: line)
      }
      exp.fulfill()
    })
    action()
    wait(for: [exp], timeout: 1.0)
  }
  
  func failure(_ with: LocalFeedImageDataLoader.LoadError) -> LocalFeedImageDataLoader.Result {
    return .failure(with)
  }
}
