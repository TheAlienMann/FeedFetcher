//
//  CacheFeedImageDataUseCaseTests.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherCache

class CacheFeedImageDataUseCaseTests: XCTestCase {
  func test_init_doesNotRequestStoreToInsertData() {
    let (_, store) = makeSUT()
    
    XCTAssertEqual(store.messages, [], "Loader should not request to save any data at creation.")
  }
  
  func test_saveImageData_doesRequestStoreToInsertData() {
    let (sut, store) = makeSUT()
    let aData = anyData()
    let aURL = anyURL()
    
    sut.saveImageData(aData, for: aURL, completion: { _ in })
    
    XCTAssertEqual(store.messages, [.insertImageData(aData, for: aURL)], "Expected loader to request store to insert data at saveImageData.")
  }
  
  func test_saveImageDataTwice_doesRequestStoreToInsertDataTwice() {
    let (sut, store) = makeSUT()
    let aURL = anyURL()
    let aData = anyData()
    let otherURL = URL(string: "http://other-url.com")!
    let otherData = Data("other data".utf8)
    
    sut.saveImageData(aData, for: aURL, completion: { _ in })
    sut.saveImageData(otherData, for: otherURL, completion: { _ in })
    
    XCTAssertEqual(store.messages, [.insertImageData(aData, for: aURL), .insertImageData(otherData, for: otherURL)], "Expected loader to request store to insert data as many times as required.")
  }
  
  func test_saveSameDataTwice_doesNotOverrideInsertedData() {
    let (sut, store) = makeSUT()
    let aData = anyData()
    let aURL = anyURL()
    
    sut.saveImageData(aData, for: aURL, completion: { _ in })
    sut.saveImageData(aData, for: aURL, completion: { _ in })
    
    XCTAssertEqual(store.messages, [.insertImageData(aData, for: aURL), .insertImageData(aData, for: aURL)], "Expected not to override inserted data, and to store it as many times as requested.")
  }
  
  func test_saveSameData_completesWithFailedErrorOnInsertionError() {
    let (sut, store) = makeSUT()
    
    saveImageData(sut, andExpect: failure(.failed), when: {
      store.completeInsertionWithError()
    })
  }
  
  func test_saveImageData_completesWithNoErrorOnInsertionSuccess() {
    let (sut, store) = makeSUT()
    
    saveImageData(sut, andExpect: .success(()), when: {
      store.completeInsertionWith(data: anyData())
    })
  }
  
  func test_saveImageData_doesNotCompleteOnLoaderDeallocation() {
    let store = FeedImageDataStoreSpy()
    var sut: LocalFeedImageDataLoader? = .init(store: store)
    let aData = anyData()
    let aURL = anyURL()
    
    sut?.saveImageData(aData, for: aURL, completion: { _ in
      XCTFail("Expected saveImageData to not complete if loader if deallocated.")
    })
    
    sut = nil
    store.completeInsertionWithError()
    store.completeInsertionWith(data: aData)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
    let store = FeedImageDataStoreSpy()
    let sut = LocalFeedImageDataLoader(store: store)
    
    trackForMemoryLeak(store, file: file, line: line)
    trackForMemoryLeak(sut, file: file, line: line)
    
    return (sut, store)
  }
  
  func saveImageData(_ sut: LocalFeedImageDataLoader, andExpect expected: LocalFeedImageDataLoader.SaveResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Waiting save image data to complete.")
    
    sut.saveImageData(anyData(), for: anyURL(), completion: { result in
      switch (expected, result) {
        case (.success, .success):
          break
        case let (.failure(expectedError as LocalFeedImageDataLoader.SaveError), .failure(receivedError as LocalFeedImageDataLoader.SaveError)):
          XCTAssertEqual(expectedError, receivedError, "Expected to fail with \(expectedError) but got \(receivedError) instead.", file: file, line: line)
        default:
          XCTFail("Expected to complete with \(expected) but got \(result) instead.", file: file, line: line)
      }
      exp.fulfill()
    })
    
    action()
    wait(for: [exp], timeout: 1.0)
  }
  
  func failure(_ error: LocalFeedImageDataLoader.SaveError) -> LocalFeedImageDataLoader.SaveResult {
    return .failure(error)
  }
}
