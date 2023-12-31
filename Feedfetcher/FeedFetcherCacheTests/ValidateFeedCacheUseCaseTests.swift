//
//  ValidateFeedCacheUseCaseTests.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherCache

class ValidateFeedCacheUseCaseTests: XCTestCase {
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_cacheRetrievalFailed_validateCache_deletesCache() {
    let (store, sut) = makeSUT()
    
    sut.validateCache(completion: { _ in })
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed, .deleteCacheFeed])
  }
  
  func test_cacheIsEmpty_validateCache_doesNotDeletesCache() {
    let currentDate = Date()
    let (store, sut) = makeSUT(currentDate: { currentDate })
    
    sut.validateCache(completion: { _ in })
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed])
  }
  
  func test_nonExpiredCache_validateCache_doesNotDeleteCache() {
    let currentDate = Date()
    let nonExpiredCacheTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: +1)
    let (store, sut) = makeSUT(currentDate: { currentDate })
    
    sut.validateCache(completion: { _ in })
    store.completeRetrieval(with: uniqueImageFeed().local, timestamp: nonExpiredCacheTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed])
  }
  
  func test_expiredCache_validateCache_deletesCache() {
    let currentDate = Date()
    let expiredCacheTimestamp = currentDate.minusFeedCacheMaxAge()
    let (store, sut) = makeSUT(currentDate: { currentDate })
    
    sut.validateCache(completion: { _ in })
    store.completeRetrieval(with: uniqueImageFeed().local, timestamp: expiredCacheTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed, .deleteCacheFeed])
  }
  
  func test_pastExpiredCache_validateCache_deletesCache() {
    let currentDate = Date()
    let pastExpiredCacheTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (store, sut) = makeSUT(currentDate: { currentDate })
    
    sut.validateCache(completion: { _ in })
    store.completeRetrieval(with: uniqueImageFeed().local, timestamp: pastExpiredCacheTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed, .deleteCacheFeed])
  }
  
  func test_validateCache_failsDeletionErrorOfFailedRetrieval() {
    let (store, sut) = makeSUT()
    let deletionError = anyNSError()
    
    expectValidate(sut, toCompleteWith: .failure(deletionError), when: {
      store.completeRetrieval(with: anyNSError())
      store.completeDeletion(with: deletionError)
    })
  }
  
  func test_validateCache_succeedsOnDeletionErrorOfFailedRetrieval() {
    let (store, sut) = makeSUT()
    
    expectValidate(sut, toCompleteWith: .success(()), when: {
      store.completeRetrieval(with: anyNSError())
      store.completeDeletionSuccessfully()
    })
  }
  
  func test_validateCache_succeedsOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    expectValidate(sut, toCompleteWith: .success(()), when: {
      store.completeRetrievalWithEmptyCache()
    })
  }
  
  func test_validateCache_succeedsOnNonExpiredCache() {
    let (store, sut) = makeSUT()
    let nonExpiredCacheTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: +1)
    
    expectValidate(sut, toCompleteWith: .success(()), when: {
      store.completeRetrieval(with: [], timestamp: nonExpiredCacheTimestamp)
    })
  }
  
  func test_validateCache_failsOnDeletionErrorOfExpiredCache() {
    let (store, sut) = makeSUT()
    let deletionError = anyNSError()
    let expiredCacheTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
    
    expectValidate(sut, toCompleteWith: .failure(deletionError), when: {
      store.completeRetrieval(with: [], timestamp: expiredCacheTimestamp)
      store.completeDeletion(with: deletionError)
    })
  }
  
  func test_validateCache_succeedsOnSuccessfulDeletionOfExpiredCache() {
    let (store, sut) = makeSUT()
    let expiredCacheTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
    
    expectValidate(sut, toCompleteWith: .success(()), when: {
      store.completeRetrieval(with: [], timestamp: expiredCacheTimestamp)
      store.completeDeletionSuccessfully()
    })
  }
  
  func test_feedLoaderIsDeallocated_validateCache_doesNotDeleteCache() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    sut?.validateCache(completion: { _ in })
    
    sut = nil
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieveCacheFeed])
  }
  
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    
    trackForMemoryLeak(store, file: file, line: line)
    trackForMemoryLeak(sut, file: file, line: line)
    
    return (store, sut)
  }
  
  private func expectValidate(_ sut: LocalFeedLoader, toCompleteWith expected: LocalFeedLoader.ValidateResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Waiting for validate cache to complete.")
    
    sut.validateCache(completion: { result in
      switch (expected, result) {
        case (.success, .success):
          break
        case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
          XCTAssertEqual(expectedError, receivedError, "Validate cache expected to fail with error \(expectedError) but got error \(receivedError) instead.", file: file, line: line)
        default:
          XCTFail("Validate cache expected to complete with \(expected) but got \(result) instead.", file: file, line: line)
      }
      exp.fulfill()
    })
    action()
    wait(for: [exp], timeout: 1.0)
  }
}
