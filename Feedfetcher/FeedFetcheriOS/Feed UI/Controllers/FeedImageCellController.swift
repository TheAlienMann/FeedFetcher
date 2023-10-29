//
//  FeedImageCellController.swift
//

import Foundation
import UIKit
import Feedfetcher

public protocol FeedImageCellControllerDelegate {
  func didRequestImage()
  func didCancelImageRequest()
}

public final class FeedImageCellController: FeedImageView {
  private let delegate: FeedImageCellControllerDelegate
  private var cell: FeedImageCell?
  
  public init(delegate: FeedImageCellControllerDelegate) {
    self.delegate = delegate
  }
  
  func view(in tableView: UITableView) -> UITableViewCell {
    cell = tableView.dequeueReusableCell()
    delegate.didRequestImage()
    
    return cell!
  }
  
  func preload() {
    delegate.didRequestImage()
  }
  
  func cancelLoad() {
    delegate.didCancelImageRequest()
    releaseCellForReuse()
  }
  
  public func display(_ model: FeedImageViewModel<UIImage>) {
    cell?.locationContainer.isHidden = !model.hasLocation
    cell?.locationLabel.text = model.location
    cell?.descriptionLabel.text = model.description
    cell?.feedImageView.setImageAnimation(model.image)
    cell?.feedImageContainer.isShimmering = model.isLoading
    cell?.feedImageRetryButton.isHidden = !model.shouldRetry
    cell?.onRetry = delegate.didRequestImage
  }
  
  private func releaseCellForReuse() {
    cell = nil
  }
}
