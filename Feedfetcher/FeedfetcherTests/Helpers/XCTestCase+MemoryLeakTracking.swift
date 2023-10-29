//
//  XCTestCase+MemoryLeakTracking.swift
//

import Foundation
import XCTest

extension XCTestCase {
  func trackForMemoryLeak(_ instance: AnyObject, file: StaticString, line: UInt) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Check for Possible Memory Leak.", file: file, line: line)
    }
  }
}
