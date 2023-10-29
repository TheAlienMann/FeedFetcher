//
//  SharedTestsHelpers.swift
//

import Foundation
import Feedfetcher

func anyNSError() -> NSError {
  return NSError(domain: "test", code: 0, userInfo: nil)
}

func anyURL() -> URL {
  return URL(string: "http://any-url.com")!
}

func anyData() -> Data {
  return Data("any-data".utf8)
}

func uniqueImage() -> FeedImage {
  return FeedImage(
    id: UUID(),
    url: anyURL(),
    description: "any description",
    location: "any location")
}
