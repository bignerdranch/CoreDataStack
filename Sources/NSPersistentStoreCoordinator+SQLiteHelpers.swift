//
//  NSPersistentStoreCoordinator+Extensions.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 5/8/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public extension NSPersistentStoreCoordinator {

    /**
     Default persistent store options used for the `SQLite` backed `NSPersistentStoreCoordinator`
     */
    public static var stockSQLiteStoreOptions: [NSObject: AnyObject] {
        return [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]
    }

    /**
     Asynchronously creates an `NSPersistentStoreCoordinator` and adds a `SQLite` based store.

     - parameter managedObjectModel: The `NSManagedObjectModel` describing the data model.
     - parameter storeFileURL: The URL where the SQLite store file will reside.
     - parameter queue: Optional GCD queue on which to add the store. Defaults to a global background queue.
     - parameter completion: A completion closure with a `CoordinatorResult` that will be executed following the `NSPersistentStore` being added to the `NSPersistentStoreCoordinator`.
     */
    public class func setupSQLiteBackedCoordinator(managedObjectModel: NSManagedObjectModel,
                                                   storeFileURL: NSURL,
                                                   queue: dispatch_queue_t = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                                                   completion: (CoreDataStack.CoordinatorResult) -> Void) {
        dispatch_async(queue) {
            do {
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                           configuration: nil,
                                                           URL: storeFileURL,
                                                           options: stockSQLiteStoreOptions)
                completion(.Success(coordinator))
            } catch let error {
                completion(.Failure(error))
            }
        }
    }
}
