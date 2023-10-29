//
//  FeedImage.swift
//

import Foundation

public struct FeedImage: Equatable {
  public private(set) var id: UUID
  public private(set) var url: URL
  public private(set) var description: String?
  public private(set) var location: String?
  
  public init(id: UUID, url: URL, description: String? = nil, location: String? = nil) {
    self.id = id
    self.url = url
    self.description = description
    self.location = location
  }
}
