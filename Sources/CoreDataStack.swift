//
//  CoreDataStack.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 12/8/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Action callbacks
public typealias CoreDataStackSetupCallback = CoreDataStack.SetupResult -> Void
public typealias CoreDataStackStoreResetCallback = CoreDataStack.ResetResult -> Void
public typealias CoreDataStackBatchMOCCallback = CoreDataStack.BatchContextResult -> Void

// MARK: - Error Handling

/**
 Three layer Core Data stack comprised of:

 * A primary background queue context with an `NSPersistentStoreCoordinator`
 * A main queue context that is a child of the primary queue
 * A method for spawning many background worker contexts that are children of the main queue context

 Calling `save()` on any `NSMangedObjectContext` belonging to the stack will automatically bubble the changes all the way to the `NSPersistentStore`
 */
@available(iOS, introduced=8.0, deprecated=10.0, message="Use NSPersistentContainer")
@available(tvOS, introduced = 9.0, deprecated = 10.0, message = "Use NSPersistentContainer")
@available(OSX, introduced=10.10, deprecated=10.12, message="Use NSPersistentContainer")
public final class CoreDataStack {

    /// CoreDataStack specific ErrorTypes
    public enum Error: ErrorType {
        /// Case when an `NSPersistentStore` is not found for the supplied store URL
        case StoreNotFoundAt(url: NSURL)
        /// Case when an In-Memory store is not found
        case InMemoryStoreMissing
        /// Case when the store URL supplied to contruct function cannot be used
        case UnableToCreateStoreAt(url: NSURL)
    }

    /**
     Primary persisting background managed object context. This is the top level context that possess an
     `NSPersistentStoreCoordinator` and saves changes to disk on a background queue.

     Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.

     note: `NSBatchUpdateRequest` and `NSAsynchronousFetchRequest` require a context with a persistent store connected directly.
     */
    public private(set) lazy var privateQueueContext: NSManagedObjectContext = {
        return self.constructPersistingContext()
    }()
    private func constructPersistingContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        managedObjectContext.name = "Primary Private Queue Context (Persisting Context)"
        return managedObjectContext
    }

    /**
     The main queue context for any work that will be performed on the main queue.
     Its parent context is the primary private queue context that persist the data to disk.
     Making a `save()` call on this context will automatically trigger a save on its parent via `NSNotification`.
     */
    public private(set) lazy var mainQueueContext: NSManagedObjectContext = {
        return self.constructMainQueueContext()
    }()
    private func constructMainQueueContext() -> NSManagedObjectContext {
        var managedObjectContext: NSManagedObjectContext!
        let setup: () -> Void = {
            managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
            managedObjectContext.parentContext = self.privateQueueContext

            NSNotificationCenter.defaultCenter().addObserver(self,
                                                             selector: #selector(CoreDataStack.stackMemberContextDidSaveNotification(_:)),
                                                             name: NSManagedObjectContextDidSaveNotification,
                                                             object: managedObjectContext)
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
    }

    // MARK: - Lifecycle

    /**
     Creates a `SQLite` backed Core Data stack for a given model in the supplied `NSBundle`.

     - parameter modelName: Base name of the `XCDataModel` file.
     - parameter inBundle: NSBundle that contains the `XCDataModel`. Default value is mainBundle()
     - parameter withStoreURL: Optional URL to use for storing the `SQLite` file. Defaults to "(modelName).sqlite" in the Documents directory.
     - parameter callbackQueue: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter callback: The `SQLite` persistent store coordinator will be setup asynchronously.
                            This callback will be passed either an initialized `CoreDataStack` object or an `ErrorType` value.
     */
    public static func constructSQLiteStack(withModelName
        modelName: String,
        inBundle bundle: NSBundle = NSBundle.mainBundle(),
                 withStoreURL desiredStoreURL: NSURL? = nil,
                              callbackQueue: dispatch_queue_t? = nil,
                              callback: CoreDataStackSetupCallback) {

        let model = bundle.managedObjectModel(modelName)
        let storeFileURL = desiredStoreURL ?? NSURL(string: "\(modelName).sqlite", relativeToURL: documentsDirectory)!
        do {
            try createDirectoryIfNecessary(storeFileURL)
        } catch {
            callback(.Failure(Error.UnableToCreateStoreAt(url: storeFileURL)))
            return
        }

        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        let callbackQueue: dispatch_queue_t = callbackQueue ?? backgroundQueue
        NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(
            model,
            storeFileURL: storeFileURL) { coordinatorResult in
                switch coordinatorResult {
                case .Success(let coordinator):
                    let stack = CoreDataStack(modelName : modelName,
                                              bundle: bundle,
                                              persistentStoreCoordinator: coordinator,
                                              storeType: .SQLite(storeURL: storeFileURL))
                    dispatch_async(callbackQueue) {
                        callback(.Success(stack))
                    }
                case .Failure(let error):
                    dispatch_async(callbackQueue) {
                        callback(.Failure(error))
                    }
                }
        }
    }

    private static func createDirectoryIfNecessary(url: NSURL) throws {
        let fileManager = NSFileManager.defaultManager()
        guard let directory = url.URLByDeletingLastPathComponent else {
            throw Error.UnableToCreateStoreAt(url: url)
        }
        try fileManager.createDirectoryAtURL(directory, withIntermediateDirectories: true, attributes: nil)
    }

    /**
     Creates an in-memory Core Data stack for a given model in the supplied `NSBundle`.

     This stack is configured with the same concurrency and persistence model as the `SQLite` stack, but everything is in-memory.

     - parameter modelName: Base name of the `XCDataModel` file.
     - parameter inBundle: `NSBundle` that contains the `XCDataModel`. Default value is `mainBundle()`

     - throws: Any error produced from `NSPersistentStoreCoordinator`'s `addPersistentStoreWithType`

     - returns: CoreDataStack: Newly created In-Memory `CoreDataStack`
     */
    public static func constructInMemoryStack(withModelName modelName: String,
                                                            inBundle bundle: NSBundle = NSBundle.mainBundle()) throws -> CoreDataStack {
        let model = bundle.managedObjectModel(modelName)
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
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        didSet {
            privateQueueContext = constructPersistingContext()
            privateQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
            mainQueueContext = constructMainQueueContext()
        }
    }
    private var managedObjectModel: NSManagedObjectModel {
        get {
            return bundle.managedObjectModel(managedObjectModelName)
        }
    }

    private init(modelName: String, bundle: NSBundle, persistentStoreCoordinator: NSPersistentStoreCoordinator, storeType: StoreType) {
        self.bundle = bundle
        self.storeType = storeType
        managedObjectModelName = modelName

        self.persistentStoreCoordinator = persistentStoreCoordinator
        privateQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private let saveBubbleDispatchGroup = dispatch_group_create()
}

public extension CoreDataStack {
    // These will be replaced with Box/Either or something native to Swift (fingers crossed) https://github.com/bignerdranch/CoreDataStack/issues/10

    // MARK: - Operation Result Types

    /// Result containing either an instance of `NSPersistentStoreCoordinator` or `ErrorType`
    public enum CoordinatorResult {
        /// A success case with associated `NSPersistentStoreCoordinator` instance
        case Success(NSPersistentStoreCoordinator)
        /// A failure case with associated `ErrorType` instance
        case Failure(ErrorType)
    }
    /// Result containing either an instance of `NSManagedObjectContext` or `ErrorType`
    public enum BatchContextResult {
        /// A success case with associated `NSManagedObjectContext` instance
        case Success(NSManagedObjectContext)
        /// A failure case with associated `ErrorType` instance
        case Failure(ErrorType)
    }
    /// Result containing either an instance of `CoreDataStack` or `ErrorType`
    public enum SetupResult {
        /// A success case with associated `CoreDataStack` instance
        case Success(CoreDataStack)
        /// A failure case with associated `ErrorType` instance
        case Failure(ErrorType)
    }
    /// Result of void representing `Success` or an instance of `ErrorType`
    public enum SuccessResult {
        /// A success case
        case Success
        /// A failure case with associated ErrorType instance
        case Failure(ErrorType)
    }
    public typealias SaveResult = SuccessResult
    public typealias ResetResult = SuccessResult
}

public extension CoreDataStack {
    /**
     This function resets the `NSPersistentStore` connected to the `NSPersistentStoreCoordinator`.
     For `SQLite` based stacks, this function will also remove the `SQLite` store from disk.

     - parameter callbackQueue: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter resetCallback: A callback with a `Success` or an `ErrorType` value with the error
     */
    public func resetStore(callbackQueue: dispatch_queue_t? = nil, resetCallback: CoreDataStackStoreResetCallback) {
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        let callbackQueue: dispatch_queue_t = callbackQueue ?? backgroundQueue
        dispatch_group_notify(self.saveBubbleDispatchGroup, backgroundQueue) {
            switch self.storeType {
            case .InMemory:
                do {
                    guard let store = self.persistentStoreCoordinator.persistentStores.first else {
                        resetCallback(.Failure(Error.InMemoryStoreMissing))
                        break
                    }
                    try self.persistentStoreCoordinator.performAndWaitOrThrow {
                        try self.persistentStoreCoordinator.removePersistentStore(store)
                        try self.persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
                    }
                    dispatch_async(callbackQueue) {
                        resetCallback(.Success)
                    }
                } catch {
                    dispatch_async(callbackQueue) {
                        resetCallback(.Failure(error))
                    }
                }
                break

            case .SQLite(let storeURL):
                let coordinator = self.persistentStoreCoordinator
                let mom = self.managedObjectModel

                guard let store = coordinator.persistentStoreForURL(storeURL) else {
                    let error = Error.StoreNotFoundAt(url: storeURL)
                    resetCallback(.Failure(error))
                    break
                }

                do {
                    if #available(iOS 9, OSX 10.11, *) {
                        try coordinator.destroyPersistentStoreAtURL(storeURL, withType: NSSQLiteStoreType, options: nil)
                    } else {
                        let fm = NSFileManager()
                        try coordinator.performAndWaitOrThrow {
                            try coordinator.removePersistentStore(store)
                            try fm.removeItemAtURL(storeURL)

                            // Remove journal files if present
                            // Eat the error because different versions of SQLite might have different journal files
                            if let indexURL = storeURL.URLByAppendingPathComponent("-shm") {
                                let _ = try? fm.removeItemAtURL(indexURL)
                            }
                            if let walFile = storeURL.URLByAppendingPathComponent("-wal") {
                                let _ = try? fm.removeItemAtURL(walFile)
                            }
                        }
                    }
                } catch let resetError {
                    dispatch_async(callbackQueue) {
                        resetCallback(.Failure(resetError))
                    }
                    return
                }

                // Setup a new stack
                NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(mom, storeFileURL: storeURL) { result in
                    switch result {
                    case .Success (let coordinator):
                        self.persistentStoreCoordinator = coordinator
                        dispatch_async(callbackQueue) {
                            resetCallback(.Success)
                        }

                    case .Failure (let error):
                        dispatch_async(callbackQueue) {
                            resetCallback(.Failure(error))
                        }
                    }
                }
            }
        }
    }
}

public extension CoreDataStack {
    /**
     Returns a new background worker `NSManagedObjectContext` as a child of the main queue context.

     Calling `save()` on this managed object context will automatically trigger a save on its parent context via `NSNotification` observing.

     - returns: `NSManagedObjectContext` The new worker context.
     */
    @available(*, deprecated, message="Use 'newChildContext(concurrencyType:name:)'")
    public func newBackgroundWorkerMOC() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.parentContext = self.mainQueueContext
        moc.name = "Background Worker Context"

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(stackMemberContextDidSaveNotification(_:)),
                                                         name: NSManagedObjectContextDidSaveNotification,
                                                         object: moc)

        return moc
    }

    /**
     Returns a new `NSManagedObjectContext` as a child of the main queue context.

     Calling `save()` on this managed object context will automatically trigger a save on its parent context via `NSNotification` observing.

     - parameter concurrencyType: The NSManagedObjectContextConcurrencyType of the new context.
     **Note** this function will trap on a preconditionFailure if you attempt to create a MainQueueConcurrencyType context from a background thread.
     Default value is .PrivateQueueConcurrencyType
     - parameter name: A name for the new context for debugging purposes. Defaults to *Main Queue Context Child*

     - returns: `NSManagedObjectContext` The new worker context.
     */
    public func newChildContext(concurrencyType concurrencyType: NSManagedObjectContextConcurrencyType = .PrivateQueueConcurrencyType,
                                                name: String? = "Main Queue Context Child") -> NSManagedObjectContext {
        if concurrencyType == .MainQueueConcurrencyType && !NSThread.isMainThread() {
            preconditionFailure("Main thread MOCs must be created on the main thread")
        }

        let moc = NSManagedObjectContext(concurrencyType: concurrencyType)
        moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyStoreTrumpMergePolicyType)
        moc.parentContext = mainQueueContext
        moc.name = name

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(stackMemberContextDidSaveNotification(_:)),
                                                         name: NSManagedObjectContextDidSaveNotification,
                                                         object: moc)
        return moc
    }

    /**
     Creates a new background `NSManagedObjectContext` connected to
     a discrete `NSPersistentStoreCoordinator` created with the same store used by the stack in construction.

     - parameter callbackQueue: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter setupCallback: A callback with either the new `NSManagedObjectContext` or an `ErrorType` value with the error
     */
    public func newBatchOperationContext(callbackQueue: dispatch_queue_t? = nil, setupCallback: CoreDataStackBatchMOCCallback) {
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
            let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            let callbackQueue: dispatch_queue_t = callbackQueue ?? backgroundQueue
            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { result in
                switch result {
                case .Success(let coordinator):
                    moc.persistentStoreCoordinator = coordinator
                    dispatch_async(callbackQueue) {
                        setupCallback(.Success(moc))
                    }
                case .Failure(let error):
                    dispatch_async(callbackQueue) {
                        setupCallback(.Failure(error))
                    }
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
