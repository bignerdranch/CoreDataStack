//
//  CoreDataStack.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 12/8/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

/**
Enum values representing the various stack types available in the CoreDataStack library.
*/
public enum CoreDataStackType {
    case NestedContextStack
    case SharedCoordinatorStack
}

/**
Base class for creating SQLite backed CoreData stacks.

More or less an abstract base class since the persistentStoreCoordinator is a private property.

See NestedContextStack SharedCoordinatorStack, SharedStoreStack...
*/
public class CoreDataStack: NSObject {

    private let managedObjectModelName: String
    private let bundle: NSBundle
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL: NSURL! = self.bundle.URLForResource(self.managedObjectModelName, withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    private lazy var storeURL: NSURL = {
        return NSPersistentStoreCoordinator.urlForSQLiteStore(modelName: self.managedObjectModelName)
    }()
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!

    // MARK: - Lifecycle

    public typealias CoreDataSetupCallback = (success: Bool, error: NSError?) -> Void

    /**
    Creates a SQLite backed CoreData stack for a give model in the supplyed NSBundle.

    :param: modelName Name of the xcdatamodel for the CoreData Stack.
    :param: inBundle NSBundle that contains the XCDataModel. Default value is mainBundle()
    :param: callback The persistent store cooridiator will be setup asynchronously. This callback serves as notificaton that your stack is fully intialized. _Important_ access to this class is not safe until after this callback has fired.

    :returns: CoreDataStack Newly created stack.
    */
    public required init(modelName: String, inBundle: NSBundle = NSBundle.mainBundle(), callback: CoreDataSetupCallback) {
        bundle = inBundle
        managedObjectModelName = modelName

        super.init()

        NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: nil) { (result) in
            switch result {
            case .Success(let coordinator):
                self.persistentStoreCoordinator = coordinator
                callback(success: true, error: nil)
            case .Failure(let error):
                callback(success: false, error: error)
            }
        }
    }

    /**
    Creates a CoreData stack with an in memory persistent store.
    
    :param: modelName Name of the xcdatamodel for the CoreData Stack.
    :param: inBundle NSBundle that contains the XCDataModel. Default value is mainBundle()
    
    :returns: CoreDataStack Newly created stack.
    */
    public required init(modelName: String, inBundle: NSBundle = NSBundle.mainBundle()) {
        bundle = inBundle
        managedObjectModelName = modelName

        super.init()

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var storeError: NSError?
        if persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &storeError) == nil {
            fatalError("Creating the in memory store failed: \(storeError)")
        }
    }

    // MARK: - Public Functions

    /**
    Removes the SQLite store from disk and creates a fresh NSPersistentStore.
    */
    public func resetPersistentStoreCoordinator(setupCallback: CoreDataSetupCallback) {
        persistentStoreCoordinator = nil
        var fileRemoveError: NSError?
        if !NSFileManager.defaultManager().removeItemAtURL(storeURL, error: &fileRemoveError) {
            setupCallback(success: false, error: fileRemoveError)
        } else {
            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { (result: SetupResult) in
                switch result {
                case .Success (let coordinator):
                    self.persistentStoreCoordinator = coordinator
                    setupCallback(success: true, error: nil)
                case .Failure (let error):
                    setupCallback(success: false, error: error)
                }
            }
        }
    }
}


/**
Three layer CoreData stack comprised of:

* A primary background queue context with a persistent store coordinator
* A main queue context that is a child of the primary queue
* A method for spawning many background worker contexts that are children of the main queue context

Calling save() on any NSMangedObject context, belonging to the stack, will automatically bubble the changes all the way to the NSPersistentStore
*/
public class NestedContextStack: CoreDataStack {
    /**
    Primary persisting background managed object context. This is the top level context that possess an
    NSPersistentStoreCoordinator and saves changes to disk on a background queue.

    Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.

    NSBatchUpdateRequest and NSAsynchronousFetchRequest require a context with a persistent store connected directly,
    if this was not the case this context would be marked private.

    :returns: NSManagedObjectContext The primary persisting background context.
    */
    public lazy var privateQueueContext: NSManagedObjectContext! = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.name = "Primary Private Queue Context (Persisting Context)"

        return managedObjectContext
        }()

    /**
    The main queue context for any work that will be performed on the main queue.
    Its parent context is the primary private queue context that persist the data to disk.
    Making a save() call on this context will automatically trigger a save on its parent via NSNotification.

    :returns: NSManagedObjectContext The main queue context.
    */
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

    /**
    Returns a new background worker managed object context as a child of the main queue context.
    
    Calling save() on this managed object context will automatically trigger a save on its parent context via NSNotification observing.

    :returns: NSManagedObjectContext The new worker context.
    */
    public func newBackgroundWorkerMOC() -> NSManagedObjectContext {
        let moc = StackObservingContext(concurrencyType: .PrivateQueueConcurrencyType)
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

/**
A CoreData stack comprised of:

* One primary queue context with an NSPersistentStoreCoordinator
* A method to create background worker contexts, also with the same NSPersistentStoreCoordinator

The primary queue context is updated with all changes from worker contexts saves by performing a merge via mergeChangesFromContextDidSaveNotification.
Worker contexts can opt in to getting refreshed when the main queue saves using the same mergeChangesFromContextDidSaveNotification. See func newBackgroundContext()
*/
public class SharedCoordinatorStack: CoreDataStack {
    private var backgroundContextsNeedingRefresh = NSHashTable.weakObjectsHashTable()

    /**
    Primary managed object context for main queue work.
    
    Will receive change updates from all worker managed object contexts.
    */
    public lazy var mainContext: NSManagedObjectContext! = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.name = "Main Context (Shared Coordinator Pattern)"

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

        context = StackObservingContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        context.name = "Background Context (Shared Coordinator Pattern)"

        // Refresh the main MOC with the background MOC's Changes
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mergeChangesFromBackgroundContextSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: context)

        // Optionally refresh this worker moc whenever the main MOC saves.
        if shouldReceiveUpdates {
            backgroundContextsNeedingRefresh.addObject(context)
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
        dispatch_sync(dispatch_queue_create("com.bignerdranch.coredatastack.locking.queue", nil)) { [unowned self] in
            if let contexts = self.backgroundContextsNeedingRefresh.allObjects as? [NSManagedObjectContext] {
                for context in contexts {
                    context.performBlockAndWait() {
                        context.mergeChangesFromContextDidSaveNotification(notification)
                    }
                }
            }
        }
    }
}

/**
Private subclass of NSManagedObject used to remove itself from NSNotificationCenter,
as an observer of peer and/or parent contexts save notifications.

*/
private class StackObservingContext: NSManagedObjectContext {
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
