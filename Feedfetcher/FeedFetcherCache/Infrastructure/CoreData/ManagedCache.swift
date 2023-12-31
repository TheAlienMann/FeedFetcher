//
//  ManagedCache.swift
//  FeedFetcherCache
//
//  Created by Mohamad Rahmani on 26.10.23.
//

import Foundation
import CoreData

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
  @NSManaged var timestamp: Date
  @NSManaged var images: NSOrderedSet
}

extension ManagedCache {
  @discardableResult
  static func mapFrom(_ info: (timestamp: Date, images: [LocalFeedImage]), in context: NSManagedObjectContext) -> ManagedCache {
    let cache = ManagedCache(context: context)
    cache.timestamp = info.timestamp
    cache.images = NSOrderedSet(array: info.images.map {
      return ManagedFeedImage.mapFrom($0, in: context)
    })
    
    return cache
  }
  
  func mapTo() -> (feed: [LocalFeedImage], timestamp: Date) {
    let feed = images.compactMap { $0 as? ManagedFeedImage }.map {
      return $0.mapTo()
    }
    
    return (feed: feed, timestamp: self.timestamp)
  }
}
