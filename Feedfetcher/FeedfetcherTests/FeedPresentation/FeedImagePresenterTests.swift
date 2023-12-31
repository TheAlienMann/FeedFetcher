//
//  FeedImagePresenterTests.swift
//

import Foundation
import XCTest
import Feedfetcher

class FeedImagePresenterTests: XCTestCase {
  func test_init_doesNotSendMessageToView() {
    let (_, view) = makeSUT()
    
    XCTAssertTrue(view.messages.isEmpty, "Expected no view messagees at init.")
  }
  
  func test_startLoadingImageData_displaysImageViewIsLoading() {
    let (sut, view) = makeSUT()
    let anyImage = uniqueImage()
    
    sut.didStartLoadingImageData(for: anyImage)
    
    guard let viewModel = view.messages.first else {
      return XCTFail("View Model expected not to be nil.")
    }
    
    XCTAssertNil(viewModel.image)
    XCTAssertEqual(anyImage.location, viewModel.location)
    XCTAssertEqual(anyImage.description, viewModel.description)
    XCTAssertTrue(viewModel.isLoading, "View model isLoading should be true if image data has started loading.")
    XCTAssertFalse(viewModel.shouldRetry, "ViewModel's shouldRetry be false if image data has started loading.")
  }
  
  func test_didFinishLoadingWithError_displaysImageViewShouldRetry() {
    let (sut, view) = makeSUT()
    let anyImage = uniqueImage()
    let anyError = anyNSError()
    
    sut.didFinishLoadingImageData(with: anyError, for: anyImage)
    
    guard let viewModel = view.messages.first else {
      return XCTFail("viewModel expected not to be nil")
    }
    
    XCTAssertNil(viewModel.image)
    XCTAssertEqual(anyImage.location, viewModel.location)
    XCTAssertEqual(anyImage.description, viewModel.description)
    XCTAssertFalse(viewModel.isLoading, "viewModel's isLoading should be false if image data load did finish.")
    XCTAssertTrue(viewModel.shouldRetry, "viewModel's shouldRetry be true if loaded image data is not valid.")
  }
  
  func test_didFinishLoadingAndTransformationFails_displaysImageViewShouldRetry() {
    let (sut, view) = makeSUT(transformer: failsTransformer)
    let anyImage = uniqueImage()
    let anyData = Data()
    
    sut.didFinishLoadingImageData(with: anyData, for: anyImage)
    
    guard let viewModel = view.messages.first else {
      return XCTFail("viewModel is expected not to be nil")
    }
    
    XCTAssertNil(viewModel.image)
    XCTAssertEqual(anyImage.location, viewModel.location)
    XCTAssertEqual(anyImage.description, viewModel.description)
    XCTAssertFalse(viewModel.isLoading, "viewModel's isLoading should be false if image data load did finish.")
    XCTAssertTrue(viewModel.shouldRetry, "viewModel's shouldRetry should be true if loaded image data tranform fails.")
  }
  
  func test_didFinishLoadingAndTransformationSucceed_displaysImageView() {
    let (sut, view) = makeSUT(transformer: succeedTransformer)
    let anyImage = uniqueImage()
    let anyData = Data()
    
    sut.didFinishLoadingImageData(with: anyData, for: anyImage)
    
    guard let viewModel = view.messages.first else {
      return XCTFail("viewModel is expected not to be nil.")
    }
    
    XCTAssertNotNil(viewModel.image)
    XCTAssertEqual(anyImage.location, viewModel.location)
    XCTAssertEqual(anyImage.description, viewModel.description)
    XCTAssertFalse(viewModel.isLoading, "viewModel's isLoading should be false if image data load did finish.")
    XCTAssertFalse(viewModel.shouldRetry, "viewModel's shouldRetry should be false if loaded image data transform succeeds.")
  }
  
  // MARK: - Helpers
  
  private let failsTransformer: (Data) -> AnyImage? = { _ in nil }
  private let succeedTransformer: (Data) -> AnyImage? = { _ in AnyImage() }
  
  private struct AnyImage: Equatable { }
  
  private func makeSUT(transformer: @escaping (Data) -> AnyImage? = { _ in nil }, file: StaticString = #file, line: UInt = #line) -> (sut: FeedImagePresenter<FeedImageViewSpy, AnyImage>, View: FeedImageViewSpy) {
    let view = FeedImageViewSpy()
    let sut = FeedImagePresenter<FeedImageViewSpy, AnyImage>(view: view, imageTransformer: transformer)
    
    trackForMemoryLeak(view, file: file, line: line)
    trackForMemoryLeak(sut, file: file, line: line)
    
    return (sut, view)
  }
  
  private class FeedImageViewSpy: FeedImageView {
    private(set) var messages = [FeedImageViewModel<AnyImage>]()
    
    func display(_ model: FeedImageViewModel<AnyImage>) {
      messages.append(model)
    }
  }
}
