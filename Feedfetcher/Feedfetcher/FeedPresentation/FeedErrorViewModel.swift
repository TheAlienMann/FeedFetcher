//
//  FeedErrorViewModel.swift
//

import Foundation

public struct FeedErrorViewModel: Equatable {
  public let message: String?
  
  public init(message: String?) {
    self.message = message
  }
}
