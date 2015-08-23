//
//  CoreDataStack.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 12/8/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

// TODO: rcedwards These will be replaced with Box/Either or something native to Swift (fingers crossed) https://github.com/bignerdranch/CoreDataStack/issues/10

// MARK: - Operation Result Types
public enum CoordinatorResult {
    case Success(NSPersistentStoreCoordinator)
    case Failure(ErrorType)
}
public enum BatchContextResult {
    case Success(NSManagedObjectContext)
    case Failure(ErrorType)
}
public enum SetupResult {
    case Success(CoreDataStack)
    case Failure(ErrorType)
}
public enum SuccessResult {
    case Success
    case Failure(ErrorType)
}
public typealias SaveResult = SuccessResult
public typealias ResetResult = SuccessResult

// MARK: - Action callbacks
public typealias CoreDataStackSetupCallback = SetupResult -> Void
public typealias CoreDataStackResetCallback = ResetResult -> Void
public typealias CoreDataStackBatchMOCCallback = BatchContextResult -> Void

// MARK: - Errors
public enum CoreDataStackError : ErrorType {
    case InvalidSQLiteStoreURL
}

/**
Three layer CoreData stack comprised of:

* A primary background queue context with a persistent store coordinator
* A main queue context that is a child of the primary queue
* A method for spawning many background worker contexts that are children of the main queue context

Calling save() on any NSMangedObjectContext belonging to the stack will automatically bubble the changes all the way to the NSPersistentStore
*/
public final class CoreDataStack {
    /**
    Primary persisting background managed object context. This is the top level context that possess an
    NSPersistentStoreCoordinator and saves changes to disk on a background queue.

    Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.

    NSBatchUpdateRequest and NSAsynchronousFetchRequest require a context with a persistent store connected directly,
    if this was not the case this context would be marked private.

    - returns: NSManagedObjectContext The primary persisting background context.
    */
    public let privateQueueContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        managedObjectContext.name = "Primary Private Queue Context (Persisting Context)"
        return managedObjectContext
        }()

    /**
    The main queue context for any work that will be performed on the main queue.
    Its parent context is the primary private queue context that persist the data to disk.
    Making a save() call on this context will automatically trigger a save on its parent via NSNotification.

    - returns: NSManagedObjectContext The main queue context.
    */
    public let mainQueueContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        managedObjectContext.name = "Main Queue Context (UI Context)"
        return managedObjectContext
        }()

    // MARK: - Lifecycle

    /* TODO: the distinct StoreType values are really crying out for separate `construct` functions at a minimum.
        For in-memory store types:
            - no details about the storage location are needed
            - no asynchronous behavior is performed for the callback
            - batch operations are not supported (assumes the store is on disk)
        It is also possible that you might want to create an in-memory-store-backed MOC for a CoreDataStack that uses SQLite otherwise.
    */
    /**
    Creates a SQLite backed CoreData stack for a given model in the supplied NSBundle.

    - parameter modelName: Name of the xcdatamodel for the CoreData Stack.
    - parameter inBundle: NSBundle that contains the XCDataModel. Default value is mainBundle()
    - parameter withStoreURL: Optional URL to use for storing the SQLite file. Defaults to "\(modelName).sqlite" in the Documents directory.
    - parameter callback: The SQLite persistent store coordinator will be setup asynchronously. This callback will be passed either an initialized CoreDataStack object or an ErrorType value.
    */
    public static func constructSQLiteStack(withModelName modelName: String,
        inBundle bundle: NSBundle = NSBundle.mainBundle(),
        withStoreURL desiredStoreURL: NSURL? = nil,
        callback: CoreDataStackSetupCallback) {
            let model = bundle.managedObjectModel(modelName: modelName)
            let storeFileURL = desiredStoreURL ?? NSURL(string: "\(modelName).sqlite", relativeToURL: documentsDirectory)!
            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(model, storeFileURL: storeFileURL) { coordinatorResult in
                switch coordinatorResult {
                case .Success(let coordinator):
                    let stack = CoreDataStack(modelName : modelName, bundle: bundle, persistentStoreCoordinator: coordinator, storeType: .SQLite(storeURL: storeFileURL))
                    callback(.Success(stack))
                case .Failure(let error):
                    callback(.Failure(error))
                }
            }
    }

    public static func constructInMemoryStack(withModelName modelName: String,
        inBundle bundle: NSBundle = NSBundle.mainBundle()) throws -> CoreDataStack {
            let model = bundle.managedObjectModel(modelName: modelName)
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            let stack = CoreDataStack(modelName: modelName, bundle: bundle, persistentStoreCoordinator: coordinator, storeType: .InMemory)
            return stack
    }

    // MARK: - Private Implementation

    private enum StoreType {
        case InMemory
        case SQLite(storeURL: NSURL)
    }

    private let managedObjectModelName: String
    private let storeType: StoreType
    private let bundle: NSBundle
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator
    private var managedObjectModel: NSManagedObjectModel {
        get {
            return bundle.managedObjectModel(modelName: managedObjectModelName)
        }
    }

    private init(modelName: String, bundle: NSBundle, persistentStoreCoordinator: NSPersistentStoreCoordinator, storeType: StoreType) {
        self.bundle = bundle
        self.storeType = storeType
        managedObjectModelName = modelName

        self.persistentStoreCoordinator = persistentStoreCoordinator
        privateQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
        mainQueueContext.parentContext = privateQueueContext

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "stackMemberContextDidSaveNotification:",
            name: NSManagedObjectContextDidSaveNotification,
            object: mainQueueContext)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

public extension CoreDataStack {
    /**
    Removes the SQLite store from disk and creates a fresh NSPersistentStore.
    
     - parameter resetCallback: A callback with a Success or an ErrorType value with the error
    */
    public func resetPersistentStoreCoordinator(resetCallback: CoreDataStackResetCallback) {
        switch storeType {
        case .InMemory:
            // TODO: rcedwards implement this
            break
        case .SQLite(let storeURL):
            do {
                if #available(iOS 9, *), let store = persistentStoreCoordinator.persistentStoreForURL(storeURL) {
                    try persistentStoreCoordinator.removePersistentStore(store)
                } else {
                    try NSFileManager.defaultManager().removeItemAtURL(storeURL)
                }

                NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { result in
                    switch result {
                    case .Success (let coordinator):
                        self.persistentStoreCoordinator = coordinator
                        resetCallback(.Success)
                    case .Failure (let error):
                        resetCallback(.Failure(error))
                    }
                }
            } catch let fileRemoveError {
                resetCallback(.Failure(fileRemoveError))
            }
        }
    }
}

public extension CoreDataStack {
    /**
    Returns a new background worker managed object context as a child of the main queue context.

    Calling save() on this managed object context will automatically trigger a save on its parent context via NSNotification observing.

    - returns: NSManagedObjectContext The new worker context.
    */
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

    /**
    Creates a new background managed object context connected to
    a discrete persistent store coordinator created with the same store used by the stack in construction.

    - parameter setupCallback: A callback with either the new managed object context or an ErrorType value with the error
    */
    public func newBatchOperationContext(setupCallback: CoreDataStackBatchMOCCallback) {
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyObjectTrumpMergePolicyType)
        moc.name = "Batch Operation Context"

        switch storeType {
        case .InMemory:
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            do {
                try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
                moc.persistentStoreCoordinator = coordinator
                setupCallback(.Success(moc))
            } catch {
                setupCallback(.Failure(error))
            }
        case .SQLite(let storeURL):
            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { result in
                switch result {
                case .Success(let coordinator):
                    moc.persistentStoreCoordinator = coordinator
                    setupCallback(.Success(moc))
                case .Failure(let error):
                    setupCallback(.Failure(error))
                }
            }
        }
    }
}

private extension CoreDataStack {
    @objc private func stackMemberContextDidSaveNotification(notification: NSNotification) {
        if notification.object as? NSManagedObjectContext == mainQueueContext {
            print("Saving \(privateQueueContext) as a result of \(mainQueueContext) being saved.")
            privateQueueContext.saveContext()
        } else if let notificationMOC = notification.object as? NSManagedObjectContext {
            print("Saving \(mainQueueContext) as a result of \(notificationMOC) being saved.")
            mainQueueContext.saveContext()
        } else {
            assertionFailure("Notification posted from an object other than an NSManagedObjectContext")
        }
    }
}

private extension CoreDataStack {
    private static var documentsDirectory: NSURL? {
        get {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls.first
        }
    }
}

private extension NSBundle {
    static private let modelExtension = "momd"
    func managedObjectModel(modelName modelName: String) -> NSManagedObjectModel {
        let URL = URLForResource(modelName, withExtension: NSBundle.modelExtension)!
        return NSManagedObjectModel(contentsOfURL: URL)!
    }
}
