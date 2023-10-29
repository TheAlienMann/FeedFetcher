//
//  CoreDataFeedStore+FeedImageDataStore.swift
//

import Foundation
import CoreData

extension CoreDataFeedStore: FeedImageDataStore {
  
  public func retrieveImageData(for url: URL, completion: @escaping (RetrieveResult) -> Void) {
    perform { context in
      let retrieveResult: FeedImageDataStore.RetrieveResult = Result(catching: {
        let managedImage = try Self.fetchFirstManagedImaage(for: url, from: context)
        
        return managedImage?.data
      })
      
      completion(retrieveResult)
    }
  }
  
  public func insertImageData(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void) {
    perform { context in
      let insertResult: FeedImageDataStore.InsertResult = Result(catching: {
        let managedImage = try Self.fetchFirstManagedImaage(for: url, from: context)
        managedImage?.data = data
        
        try context.saveIfHasPendingChanges()
        return ()
      })
      
      completion(insertResult)
    }
  }
  
  private static func fetchFirstManagedImaage(for url: URL, from context: NSManagedObjectContext) throws -> ManagedFeedImage? {
    let predicate = NSPredicate(format: "url == %@", argumentArray: [url])
    let request = NSFetchRequest<ManagedFeedImage>(entityName: ManagedFeedImage.entity().name!)
    
    request.predicate = predicate
    request.fetchLimit = 1
    
    return try context.fetch(request).first
  }
}
