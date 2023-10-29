//
//  CoreDataFeedStore.swift
//

import Foundation
import CoreData

public final class CoreDataFeedStore {
  private let modelName = "FeedStore"
  
  private let container: NSPersistentContainer
  private let context: NSManagedObjectContext
  
  public init(storeURL: URL) throws {
    let bundle = Bundle(for: CoreDataFeedStore.self)
    
    container = try NSPersistentContainer.load(modelName: modelName, in: bundle, storeURL: storeURL)
    context = container.newBackgroundContext()
  }
  
  func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
    let context = self.context
    context.perform {
      action(context)
    }
  }
}
