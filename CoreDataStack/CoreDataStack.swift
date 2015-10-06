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
public typealias CoreDataStackSQLiteResetCallback = ResetResult -> Void
public typealias CoreDataStackBatchMOCCallback = BatchContextResult -> Void

// MARK: - Error Handling
public enum CoreDataStackError: ErrorType {
    case StoreNotFoundAtURL(url: NSURL)
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
    */
    public let mainQueueContext: NSManagedObjectContext = {
        var managedObjectContext: NSManagedObjectContext!
        let setup: () -> Void = {
            managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
            managedObjectContext.name = "Main Queue Context (UI Context)"
        }
        // Always create the main-queue ManagedObjectContext on the main queue.
        if !NSThread.isMainThread() {
            dispatch_sync(dispatch_get_main_queue()) {
                setup()
            }
        } else {
            setup()
        }
        return managedObjectContext
        }()

    // MARK: - Lifecycle

    /**
    Creates a SQLite backed CoreData stack for a given model in the supplied NSBundle.

    - parameter modelName: Base name of the xcdatamodel file.
    - parameter inBundle: NSBundle that contains the XCDataModel. Default value is mainBundle()
    - parameter withStoreURL: Optional URL to use for storing the SQLite file. Defaults to "\\(modelName).sqlite" in the Documents directory.
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

    /**
    Creates an in-memory Core Data stack for a given model in the supplied NSBundle.
    
    This stack is configured with the same concurrency and persistence model as the SQLite stack, but everything is in-memory.

    - parameter modelName: Base name of the xcdatamodel file.
    - parameter inBundle: NSBundle that contains the XCDataModel. Default value is mainBundle()
    */
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

    private let saveBubbleDispatchGroup = dispatch_group_create()
}

public extension CoreDataStack {
    /**
    For SQLite based stacks, this function will remove the SQLite store from disk and creates a fresh NSPersistentStore.

    - parameter resetCallback: A callback with a Success or an ErrorType value with the error
    */
    public func resetSQLiteStore(resetCallback: CoreDataStackSQLiteResetCallback) {
        switch storeType {
        case .InMemory:
            assertionFailure("Function is only available for SQLite backed stacks.")
            break
        case .SQLite(let storeURL):
            let coordinator = persistentStoreCoordinator
            let mom = managedObjectModel

            guard let store = coordinator.persistentStoreForURL(storeURL) else {
                let error = CoreDataStackError.StoreNotFoundAtURL(url: storeURL)
                resetCallback(.Failure(error))
                break
            }

            let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            dispatch_group_notify(self.saveBubbleDispatchGroup, backgroundQueue) {
                do {
                    if #available(iOS 9, *) {
                        try coordinator.destroyPersistentStoreAtURL(storeURL, withType: NSSQLiteStoreType, options: nil)
                    } else {
                        try coordinator.performAndWait() {
                            try coordinator.removePersistentStore(store)
                            try NSFileManager.defaultManager().removeItemAtURL(storeURL)

                            // Remove journal files if present
                            let _ = try? NSFileManager.defaultManager().removeItemAtURL(storeURL.URLByAppendingPathComponent("-shm"))
                            let _ = try? NSFileManager.defaultManager().removeItemAtURL(storeURL.URLByAppendingPathComponent("-wal"))
                        }
                    }
                } catch let resetError {
                    resetCallback(.Failure(resetError))
                    return
                }

                // Setup a new stack
                NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(mom, storeFileURL: storeURL) { result in
                    switch result {
                    case .Success (let coordinator):
                        self.persistentStoreCoordinator = coordinator
                        resetCallback(.Success)
                    case .Failure (let error):
                        resetCallback(.Failure(error))
                    }
                }
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
        guard let notificationMOC = notification.object as? NSManagedObjectContext else {
            assertionFailure("Notification posted from an object other than an NSManagedObjectContext")
            return
        }
        guard let parentContext = notificationMOC.parentContext else {
            return
        }

        dispatch_group_enter(saveBubbleDispatchGroup)
        parentContext.saveContext() { _ in
            dispatch_group_leave(self.saveBubbleDispatchGroup)
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

private extension NSPersistentStoreCoordinator {
    private func performAndWait<Return>(body: () throws -> Return) throws -> Return {
        var value: Return!
        var error: ErrorType?

        performBlockAndWait {
            do {
                value = try body()
            } catch let theError {
                error = theError
            }
        }

        if let error = error {
            throw error
        } else {
            return value
        }
    }
}
