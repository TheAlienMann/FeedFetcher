//
//  UIImageView+Animations.swift
//

import Foundation
import UIKit

extension UIImageView {
  func setImageAnimation(_ newImage: UIImage?) {
    image = newImage
    
    guard newImage != nil else { return }
    
    alpha = 0
    UIView.animate(withDuration: 0.25, animations: {
      self.alpha = 1.0
    })
  }
}
