//
//  RemoteFeedItem.swift
//

import Foundation
import Feedfetcher

struct RemoteFeedItem: Codable {
  var id: UUID
  var image: URL
  var description: String?
  var location: String?
  
  var feedItem: FeedImage {
    return FeedImage(
      id: id,
      url: image,
      description: description,
      location: location)
  }
}
