//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherCache

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
  func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNotNil(deletionError, "Expected cache deletion to fail.", file: file, line: line)
  }
  
  func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    deleteCache(from: sut)
    
    expect(sut, toRetrieve: .success(nil), file: file, line: line)
  }
}
