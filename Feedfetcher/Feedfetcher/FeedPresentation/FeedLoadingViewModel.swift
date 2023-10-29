//
//  FeedLoadingViewModel.swift
//

import Foundation

public struct FeedLoadingViewModel: Equatable {
  public let isLoading: Bool
  
  public init(isLoading: Bool) {
    self.isLoading = isLoading
  }
}
