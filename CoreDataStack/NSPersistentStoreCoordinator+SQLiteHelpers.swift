//
//  NSPersistentStoreCoordinator+Extensions.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 5/8/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public enum SetupResult {
    case Success(NSPersistentStoreCoordinator)
    case Failure(NSError)
}

public extension NSPersistentStoreCoordinator {

    public class func urlForSQLiteStore(#modelName: String?) -> NSURL {
        return defaultURL(modleName: modelName)
    }

    public class func setupSQLiteBackedCoordinator(managedObjectModel: NSManagedObjectModel, storeFileURL: NSURL?, completion: (SetupResult) -> Void) {
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(backgroundQueue) {
            var error: NSError?
            if let coordinator = NSPersistentStoreCoordinator.persistentStoreCoordinator(managedObjectModel: managedObjectModel, storeURL: storeFileURL, error:&error) {
                completion(SetupResult.Success(coordinator))
            } else if let error = error {
                completion(SetupResult.Failure(error))
            } else {
                fatalError("A coordinator or error should be returned")
            }
        }
    }

    private class func persistentStoreCoordinator(#managedObjectModel: NSManagedObjectModel, storeURL: NSURL?, error: NSErrorPointer) -> NSPersistentStoreCoordinator? {
        let url = storeURL ?? defaultURL(modleName: nil)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        var storeOptions: [NSObject: AnyObject] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]

        /* If a migration is required use a journal_mode of DELETE 
            see: http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
        */
        if NSPersistentStoreCoordinator.storeRequiresMigration(storeURL: url, managedObjectModel: managedObjectModel) {
            storeOptions = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true,
                NSSQLitePragmasOption: ["journal_mode": "DELETE"]
            ]
        }

        if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
            configuration: nil,
            URL: url,
            options: storeOptions,
            error: error) {
                return coordinator
        } else if error.memory == nil {
            assertionFailure("Failed to add store and no error was returned")
        }

        return nil
    }

    private class func defaultURL(#modleName: String?) -> NSURL {
        let name = modleName ?? "coredatastore"
        return applicationDocumentsDirectory.URLByAppendingPathComponent("\(name).sqlite")
    }

    private class func storeRequiresMigration(#storeURL: NSURL, managedObjectModel: NSManagedObjectModel) -> Bool {
        var error: NSError?
        var migrationNeeded = false
        if let storeMeta = NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: storeURL, error: &error) {
            migrationNeeded = managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: storeMeta)
        } else {
            fatalError("Recovery from this point will be difficult. Failed with error: \(error)")
        }

        return migrationNeeded
    }

    private static var applicationDocumentsDirectory: NSURL {
        get {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.count-1] as! NSURL
        }
    }
}

