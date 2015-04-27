//
//  CoreDataStack.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 12/8/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

public enum CoreDataStackType {
    case ThreadConfined
    case NestedMOC
}

public class CoreDataStack: NSObject {

    private let managedObjectModelName: String
    private var bundle: NSBundle = NSBundle.mainBundle()
    private var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()

    private lazy var sqliteFileURL: NSURL = {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.managedObjectModelName).sqlite")
        }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL: NSURL! = self.bundle.URLForResource(self.managedObjectModelName, withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator! = {
        return self.createPersistantStoreCoordinator()
        }()

    // MARK: - Lifecycle

    public required init(modelName: String) {
        managedObjectModelName = modelName
    }

    public required convenience init(modelName: String, inBundle: NSBundle) {
        self.init(modelName: modelName)
        bundle = inBundle
    }

    // MARK: - Public Functions

    public func resetPersistantStoreCoordinator() {
        persistentStoreCoordinator = nil
        var fileRemoveError: NSError?
        if !NSFileManager.defaultManager().removeItemAtURL(sqliteFileURL, error: &fileRemoveError) {
            assertionFailure("Failure removing the old SQLite Store: \(fileRemoveError)")
        } else {
            persistentStoreCoordinator = createPersistantStoreCoordinator()
        }
    }

    // MARK: - Private Functions

    private func createPersistantStoreCoordinator() -> NSPersistentStoreCoordinator {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let storeOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true];
        var error: NSError? = nil
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType,
            configuration: nil,
            URL: sqliteFileURL, 
            options: nil,
            error: &error) == nil {
            coordinator = nil
             assertionFailure("Unresolved CoreData error while seeting PersistentStoreCoordinator \(error), \(error!.userInfo)")
        }
        return coordinator!
    }
}

public class NestedMOCStack: CoreDataStack {
    public lazy var privateQueueContext: NSManagedObjectContext! = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.name = "Primary Private Queue Context (Persisting Context)"

        return managedObjectContext
        }()

    public lazy var mainQueueContext: NSManagedObjectContext! = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.parentContext = self.privateQueueContext
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.name = "Main Queue Context (UI Context)"

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "stackMemberContextDidSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: moc)

        return moc
        }()

    // MARK: - Working MOCs
    public func newBackgroundWorkerMOC() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.parentContext = self.mainQueueContext
        moc.name = "Background Worker Context"

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "stackMemberContextDidSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: moc)

        return moc
    }

    // MARK: - Saving
    @objc private func stackMemberContextDidSaveNotification(notification: NSNotification) {
        var success = false
        if notification.object as? NSManagedObjectContext == mainQueueContext {
            println("Saving \(privateQueueContext) as a result of \(mainQueueContext) being saved.")
            privateQueueContext.saveContext()
        } else if let notificationMOC = notification.object as? NSManagedObjectContext {
            println("Saving \(mainQueueContext) as a result of \(notificationMOC) being saved.")
            mainQueueContext.saveContext()
        } else {
            fatalError("Notification posted from an object other than an NSManagedObjectContext")
        }
    }
}

public class ThreadConfinementStack: CoreDataStack {
    private var backgroundContextsNeedingRefresh = [NSManagedObjectContext]()

    /**
    Primary managed object context for main queue work.
    
    Will receive change updates from all worker managed object contexts.
    */
    public lazy var mainContext: NSManagedObjectContext! = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.name = "Main Context (Thread Confinement Pattern)"

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mergeChangedFromMainQueueContextSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: moc)

        return moc
        }()

    /**
    Creates a new background managed object context for performing work on a background queue.

    :param: shouldReceiveUpdates A boolean value specifying if this background context
                                    should be refreshed with save changes 
                                    from the main queue managed object context. 
                                    The main queue context will be updated with changes from this context
                                    irrespective to this property value.
                                    Default value is false.

    :returns: NSManagedObjectContext The new background context.
    */
    public func newBackgroundContext(shouldReceiveUpdates: Bool = false) -> NSManagedObjectContext {
        var context: NSManagedObjectContext!

        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        context.name = "Background Context (Thread Confinement Pattern)"

        // Refresh the main MOC with the background MOC's Changes
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mergeChangesFromBackgroundContextSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: context)

        // Optionally refresh this worker moc whenever the main MOC saves.
        if shouldReceiveUpdates {
            backgroundContextsNeedingRefresh.append(context)
        }

        return context
    }

    // MARK: - Change Merging Notifications

    @objc private func mergeChangesFromBackgroundContextSaveNotification(notification: NSNotification) {
        mainContext.performBlockAndWait() { [unowned self] in
            self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }

    @objc private func mergeChangedFromMainQueueContextSaveNotification(notification: NSNotification) {
        for context in backgroundContextsNeedingRefresh {
            context.performBlockAndWait() {
                context.mergeChangesFromContextDidSaveNotification(notification)
            }
        }
    }
}
