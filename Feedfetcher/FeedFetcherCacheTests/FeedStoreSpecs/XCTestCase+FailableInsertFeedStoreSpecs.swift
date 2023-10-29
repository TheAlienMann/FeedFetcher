//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//

import Foundation
import XCTest
import Feedfetcher
import FeedFetcherCache

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
  func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let insertionError = insert((uniqueImageFeed(), Date()), to: sut)
    
    XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error.", file: file, line: line)
  }
  
  func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueImageFeed(), Date()), to: sut)
    
    expect(sut, toRetrieve: .success(nil), file: file, line: line)
  }
}
