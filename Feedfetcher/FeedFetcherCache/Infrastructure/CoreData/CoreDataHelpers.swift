//
//  CoreDataHelpers.swift
//

import Foundation
import CoreData

internal extension NSManagedObjectContext {
  func saveIfHasPendingChanges() throws {
    if hasChanges {
      try save()
    }
  }
}

internal extension NSPersistentContainer {
  enum ConfigurationError: Error {
    case modelNotFound
    case loadingPersistentStores(Error)
  }
  
  static func load(modelName name: String, in bundle: Bundle, storeURL: URL) throws -> NSPersistentContainer {
    guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
      throw ConfigurationError.modelNotFound
    }
    
    let storeDescription = NSPersistentStoreDescription(url: storeURL)
    let container = NSPersistentContainer(name: name, managedObjectModel: model)
    container.persistentStoreDescriptions = [storeDescription]
    
    try container.loadPersistentStores()
    
    return container
  }
  
  private func loadPersistentStores() throws {
    var loadStoresError: Error?
    loadPersistentStores(completionHandler: { _, error in
      loadStoresError = error
    })
    
    if let loadStoresError = loadStoresError {
      throw ConfigurationError.loadingPersistentStores(loadStoresError)
    }
  }
}

private extension NSManagedObjectModel {
  private static var coreDataModelsExtension: String {
    return "momd"
  }
  
  static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
    guard let modelURL = bundle.url(forResource: name, withExtension: coreDataModelsExtension) else {
      return nil
    }
    
    return NSManagedObjectModel(contentsOf: modelURL)
  }
}
