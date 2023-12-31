//
//  FeedPresenter.swift
//

import Foundation

public protocol FeedLoadingView {
  func display(_ viewModel: FeedLoadingViewModel)
}

public protocol FeedView {
  func display(_ viewModel: FeedViewModel)
}

public protocol FeedErrorView {
  func display(_ viewModel: FeedErrorViewModel)
}

public final class FeedPresenter {
  private let feedView: FeedView
  private let loadingView: FeedLoadingView
  private let errorView: FeedErrorView
  
  public init(feedView: FeedView,
              loadingView: FeedLoadingView,
              errorView: FeedErrorView) {
    self.feedView = feedView
    self.loadingView = loadingView
    self.errorView = errorView
  }
  
  public func didStartLoadingFeed() {
    loadingView.display(FeedLoadingViewModel(isLoading: true))
    errorView.display(FeedErrorViewModel(message: nil))
  }
  
  public func didFinishLoadingFeed(with feed: [FeedImage]) {
    feedView.display(FeedViewModel(feed: feed))
    loadingView.display(FeedLoadingViewModel(isLoading: false))
  }
  
  public func didFinishLoadingFeed(with error: Error) {
    let errorMessage = Self.localize("LOADING_FEED_ERROR_MESSAGE", comment: "Error message when feed load fails.")
    
    errorView.display(FeedErrorViewModel(message: errorMessage))
    loadingView.display(FeedLoadingViewModel(isLoading: false))
  }
}

extension FeedPresenter {
  public static var title: String {
    return Self.localize("FEED_VIEW_TITLE", comment: "Title for the FeedView.")
  }
  
  private static func localize(_ key: String, comment: String) -> String {
    return NSLocalizedString(key, tableName: "Feed", bundle: Bundle(for: FeedPresenter.self), comment: comment)
  }
}
