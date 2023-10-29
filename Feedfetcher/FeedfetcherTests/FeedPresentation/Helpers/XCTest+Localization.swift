//
//  XCTest+Localization.swift
//

import Foundation
import XCTest
import Feedfetcher

extension XCTestCase {
  func localized(key: String, file: StaticString = #file, line: UInt = #line) -> String {
    let bundle = Bundle(for: FeedPresenter.self)
    let value = bundle.localizedString(forKey: key, value: nil, table: "Feed")
    
    if value == key {
      XCTFail("Missing localization value for key: \(key)", file: file, line: line)
    }
    
    return value
  }
}
