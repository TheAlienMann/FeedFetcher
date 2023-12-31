//
//  FeedPresenterTests.swift
//

import Foundation
import XCTest
import Feedfetcher

class FeedPresenterTests: XCTestCase {
  func test_hasTitle() {
    let localizedTitle = localized(key: "FEED_VIEW_TITLE")
    
    XCTAssertEqual(localizedTitle, FeedPresenter.title)
  }
  
  func test_init_doesNotSendMessagesToView() {
    let (_, view) = makeSUT()
    
    XCTAssertTrue(view.messages.isEmpty, "Presenter init should not send any messages to the view.")
  }
  
  func test_didStartLoading_sendsMessageDisplayView() {
    let (sut, view) = makeSUT()
    
    sut.didStartLoadingFeed()
    
    XCTAssertEqual(view.messages, [
      .loading(FeedLoadingViewModel(isLoading: true)),
      .failing(FeedErrorViewModel(message: nil))
    ])
  }
  
  func test_didFinishLoadingWithError_sendShowErrorViewAndHideLoadingView() {
    let (sut, view) = makeSUT()
    let anyError = anyNSError()
    
    sut.didFinishLoadingFeed(with: anyError)
    
    XCTAssertEqual(view.messages, [
      .failing(FeedErrorViewModel(message: localizedErrorMessage)),
      .loading(FeedLoadingViewModel(isLoading: false))
    ])
  }
  
  func test_didFinishLoadingWithFeed_sendHideLoadingViewAndDisplayFeedView() {
    let (sut, view) = makeSUT()
    let anyFeed = [uniqueImage(), uniqueImage()]
    
    sut.didFinishLoadingFeed(with: anyFeed)
    
    XCTAssertEqual(view.messages, [
      .display(FeedViewModel(feed: anyFeed)),
      .loading(FeedLoadingViewModel(isLoading: false))
    ])
  }
  
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedPresenter, view: FeedViewSpy) {
    let view = FeedViewSpy()
    let sut = FeedPresenter(feedView: view, loadingView: view, errorView: view)
    
    trackForMemoryLeak(sut, file: file, line: line)
    trackForMemoryLeak(view, file: file, line: line)
    
    return (sut, view)
  }
  
  private var localizedErrorMessage: String {
    localized(key: "LOADING_FEED_ERROR_MESSAGE")
  }
  
  private class FeedViewSpy: FeedLoadingView, FeedView, FeedErrorView {
    enum Message: Equatable {
      case loading(FeedLoadingViewModel)
      case display(FeedViewModel)
      case failing(FeedErrorViewModel)
    }
    
    private(set) var messages = [Message]()
    
    func display(_ viewModel: FeedLoadingViewModel) {
      messages.append(.loading(viewModel))
    }
    
    func display(_ viewModel: FeedViewModel) {
      messages.append(.display(viewModel))
    }
    
    func display(_ viewModel: FeedErrorViewModel) {
      messages.append(.failing(viewModel))
    }
  }
}
