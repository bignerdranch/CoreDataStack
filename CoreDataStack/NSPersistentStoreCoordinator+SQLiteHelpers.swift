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
    Default persistent store options used for the SQLite backed NSPersistentStoreCoordinator
    */
    public static var stockSQLiteStoreOptions: [NSObject: AnyObject] {
        return [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]
    }

    /**
    Asynchronously creates an NSPersistentStoreCoordinator and adds a SQLite based store.

    :param: managedObjectModel The NSManagedObjectModel describing the data model.
    :param: storeFileURL The URL where the SQLite store file will reside.
    :param: completion A completion closure with a CoordinatorResult that will be executed following the persistent store being added to the coordinator.
    */
    public class func setupSQLiteBackedCoordinator(managedObjectModel: NSManagedObjectModel, storeFileURL: NSURL, completion: (CoordinatorResult) -> Void) {
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(backgroundQueue) {
            do {
                let coordinator = try NSPersistentStoreCoordinator.persistentStoreCoordinator(managedObjectModel: managedObjectModel, storeURL: storeFileURL)
                completion(.Success(coordinator))
            } catch let error {
                completion(.Failure(error))
            }
        }
    }
}

private extension NSPersistentStoreCoordinator {
    private class func persistentStoreCoordinator(managedObjectModel managedObjectModel: NSManagedObjectModel, storeURL: NSURL) throws -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        var storeOptions = stockSQLiteStoreOptions

        /* If a migration is required use a journal_mode of DELETE
        see: http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
        */
        if existingStorePresent(storeURL: storeURL) && storeRequiresMigration(storeURL: storeURL, managedObjectModel: managedObjectModel) {
            storeOptions = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true,
                NSSQLitePragmasOption: ["journal_mode": "DELETE"]
            ]
        }

        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: storeOptions)
            return coordinator
        } catch let error as NSError {
            throw error
        }
    }

    private class func storeRequiresMigration(storeURL storeURL: NSURL, managedObjectModel: NSManagedObjectModel) -> Bool {
        var migrationNeeded = false
        do {
            let storeMeta = try metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: storeURL)
            migrationNeeded = !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: storeMeta)
        } catch let error as NSError {
            fatalError("Recovery from this point will be difficult. Failed with error: \(error)")
        }

        return migrationNeeded
    }

    private class func existingStorePresent(storeURL storeURL: NSURL) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(storeURL.path!)
    }
}
