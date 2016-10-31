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
    @available(iOS, introduced=8.0, deprecated=10.0, message="Use NSPersistentStoreDescription")
    @available(tvOS, introduced=9.0, deprecated=10.0, message="Use NSPersistentStoreDescription")
    @available(OSX, introduced=10.10, deprecated=10.12, message="Use NSPersistentStoreDescription")
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
     - parameter persistentStoreOptions: Custom options for persistent store. Default value is stockSQLiteStoreOptions
     - parameter completion: A completion closure with a `CoordinatorResult` that will be executed
                                following the `NSPersistentStore` being added to the `NSPersistentStoreCoordinator`.
     */
    @available(iOS, introduced=8.0, deprecated=10.0, message="Use NSPersistentContainer")
    @available(tvOS, introduced=9.0, deprecated=10.0, message="Use NSPersistentStoreDescription")
    @available(OSX, introduced=10.10, deprecated=10.12, message="Use NSPersistentContainer")
    public class func setupSQLiteBackedCoordinator(managedObjectModel: NSManagedObjectModel,
                                                   storeFileURL: NSURL,
                                                   persistentStoreOptions: [NSObject: AnyObject]? = stockSQLiteStoreOptions,
                                                   completion: (CoreDataStack.CoordinatorResult) -> Void) {
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(backgroundQueue) {
            do {
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                           configuration: nil,
                                                           URL: storeFileURL,
                                                           options: persistentStoreOptions)
                completion(.Success(coordinator))
            } catch let error {
                completion(.Failure(error))
            }
        }
    }
}
