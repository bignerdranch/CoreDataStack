//
//  NSPersistentStoreCoordinator+Extensions.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 5/8/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public extension NSPersistentStoreCoordinator {

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

    private class func persistentStoreCoordinator(managedObjectModel managedObjectModel: NSManagedObjectModel, storeURL: NSURL) throws -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        var storeOptions: [NSObject: AnyObject] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]

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

