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
public typealias SetupCallback = (CoreDataStack.SetupResult) -> Void
public typealias StoreResetCallback = (CoreDataStack.ResetResult) -> Void
public typealias BatchContextCallback = (CoreDataStack.BatchContextResult) -> Void

// MARK: - Error Handling

/**
 Three layer Core Data stack comprised of:

 * A primary background queue context with an `NSPersistentStoreCoordinator`
 * A main queue context that is a child of the primary queue
 * A method for spawning many background worker contexts that are children of the main queue context

 Calling `save()` on any `NSMangedObjectContext` belonging to the stack will automatically bubble the changes all the way to the `NSPersistentStore`
 */
@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use NSPersistentContainer")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use NSPersistentContainer")
public final class CoreDataStack {

    /// CoreDataStack specific ErrorTypes
    public enum Error: Swift.Error {
        /// Case when an `NSPersistentStore` is not found for the supplied store URL
        case storeNotFound(at: URL)
        /// Case when an In-Memory store is not found
        case inMemoryStoreMissing
        /// Case when the store URL supplied to contruct function cannot be used
        case unableToCreateStore(at: URL)
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
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
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
            managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            managedObjectContext.parent = self.privateQueueContext

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(CoreDataStack.stackMemberContextDidSaveNotification(_:)),
                                                   name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                   object: managedObjectContext)
        }
        // Always create the main-queue ManagedObjectContext on the main queue.
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
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
     - parameter in: NSBundle that contains the `XCDataModel`. Default value is mainBundle()
     - parameter at: Optional URL to use for storing the `SQLite` file. Defaults to "(modelName).sqlite" in the Documents directory.
     - parameter on: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter callback: The `SQLite` persistent store coordinator will be setup asynchronously.
                            This callback will be passed either an initialized `CoreDataStack` object or an `ErrorType` value.
     */
    public static func constructSQLiteStack(modelName: String,
                                            in bundle: Bundle = Bundle.main,
                                            at desiredStoreURL: URL? = nil,
                                            on callbackQueue: DispatchQueue? = nil,
                                            callback: @escaping SetupCallback) {

        let model = bundle.managedObjectModel(name: modelName)
        let storeFileURL = desiredStoreURL ?? URL(string: "\(modelName).sqlite", relativeTo: documentsDirectory!)!
        do {
            try createDirectoryIfNecessary(storeFileURL)
        } catch {
            callback(.failure(Error.unableToCreateStore(at: storeFileURL)))
            return
        }

        let backgroundQueue = DispatchQueue.global(qos: .background)
        let callbackQueue: DispatchQueue = callbackQueue ?? backgroundQueue
        NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(
            model,
            storeFileURL: storeFileURL) { coordinatorResult in
                switch coordinatorResult {
                case .success(let coordinator):
                    let stack = CoreDataStack(modelName : modelName,
                                              bundle: bundle,
                                              persistentStoreCoordinator: coordinator,
                                              storeType: .sqLite(storeURL: storeFileURL))
                    callbackQueue.async {
                        callback(.success(stack))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        callback(.failure(error))
                    }
                }
        }
    }

    private static func createDirectoryIfNecessary(_ url: URL) throws {
        let fileManager = FileManager.default
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }

    /**
     Creates an in-memory Core Data stack for a given model in the supplied `NSBundle`.

     This stack is configured with the same concurrency and persistence model as the `SQLite` stack, but everything is in-memory.

     - parameter modelName: Base name of the `XCDataModel` file.
     - parameter in: `NSBundle` that contains the `XCDataModel`. Default value is `mainBundle()`

     - throws: Any error produced from `NSPersistentStoreCoordinator`'s `addPersistentStoreWithType`

     - returns: CoreDataStack: Newly created In-Memory `CoreDataStack`
     */
    public static func constructInMemoryStack(modelName: String,
                                              in bundle: Bundle = Bundle.main) throws -> CoreDataStack {
        let model = bundle.managedObjectModel(name: modelName)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let stack = CoreDataStack(modelName: modelName, bundle: bundle, persistentStoreCoordinator: coordinator, storeType: .inMemory)
        return stack
    }

    // MARK: - Private Implementation

    private let managedObjectModelName: String
    private let bundle: Bundle

    fileprivate enum StoreType {
        case inMemory
        case sqLite(storeURL: URL)
    }

    fileprivate let storeType: StoreType
    fileprivate var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        didSet {
            privateQueueContext = constructPersistingContext()
            privateQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
            mainQueueContext = constructMainQueueContext()
        }
    }
    fileprivate var managedObjectModel: NSManagedObjectModel {
        get {
            return bundle.managedObjectModel(name: managedObjectModelName)
        }
    }
    fileprivate let saveBubbleDispatchGroup = DispatchGroup()

    private init(modelName: String, bundle: Bundle, persistentStoreCoordinator: NSPersistentStoreCoordinator, storeType: StoreType) {
        self.bundle = bundle
        self.storeType = storeType
        managedObjectModelName = modelName

        self.persistentStoreCoordinator = persistentStoreCoordinator
        privateQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

public extension CoreDataStack {
    // These will be replaced with Box/Either or something native to Swift (fingers crossed) https://github.com/bignerdranch/CoreDataStack/issues/10

    // MARK: - Operation Result Types

    /// Result containing either an instance of `NSPersistentStoreCoordinator` or `ErrorType`
    public enum CoordinatorResult {
        /// A success case with associated `NSPersistentStoreCoordinator` instance
        case success(NSPersistentStoreCoordinator)
        /// A failure case with associated `ErrorType` instance
        case failure(Swift.Error)
    }
    /// Result containing either an instance of `NSManagedObjectContext` or `ErrorType`
    public enum BatchContextResult {
        /// A success case with associated `NSManagedObjectContext` instance
        case success(NSManagedObjectContext)
        /// A failure case with associated `ErrorType` instance
        case failure(Swift.Error)
    }
    /// Result containing either an instance of `CoreDataStack` or `ErrorType`
    public enum SetupResult {
        /// A success case with associated `CoreDataStack` instance
        case success(CoreDataStack)
        /// A failure case with associated `ErrorType` instance
        case failure(Swift.Error)
    }
    /// Result of void representing `success` or an instance of `ErrorType`
    public enum SuccessResult {
        /// A success case
        case success
        /// A failure case with associated ErrorType instance
        case failure(Swift.Error)
    }
    public typealias SaveResult = SuccessResult
    public typealias ResetResult = SuccessResult
}

public extension CoreDataStack {
    /**
     This function resets the `NSPersistentStore` connected to the `NSPersistentStoreCoordinator`.
     For `SQLite` based stacks, this function will also remove the `SQLite` store from disk.

     - parameter on: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter callback: A callback with a `success` or an `ErrorType` value with the error
     */
    public func resetStore(on callbackQueue: DispatchQueue? = nil, callback: @escaping StoreResetCallback) {
        let backgroundQueue = DispatchQueue.global(qos: .background)
        let callbackQueue: DispatchQueue = callbackQueue ?? backgroundQueue
        self.saveBubbleDispatchGroup.notify(queue: backgroundQueue) {
            switch self.storeType {
            case .inMemory:
                do {
                    guard let store = self.persistentStoreCoordinator.persistentStores.first else {
                        callback(.failure(Error.inMemoryStoreMissing))
                        break
                    }
                    try self.persistentStoreCoordinator.performAndWaitOrThrow {
                        try self.persistentStoreCoordinator.remove(store)
                        try self.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
                    }
                    callbackQueue.async {
                        callback(.success)
                    }
                } catch {
                    callbackQueue.async {
                        callback(.failure(error))
                    }
                }
                break

            case .sqLite(let storeURL):
                let coordinator = self.persistentStoreCoordinator
                let mom = self.managedObjectModel

                guard let store = coordinator.persistentStore(for: storeURL) else {
                    let error = Error.storeNotFound(at: storeURL)
                    callback(.failure(error))
                    break
                }

                do {
                    if #available(iOS 9, OSX 10.11, *) {
                        try coordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
                    } else {
                        let fm = FileManager()
                        try coordinator.performAndWaitOrThrow {
                            try coordinator.remove(store)
                            try fm.removeItem(at: storeURL)

                            // Remove journal files if present
                            // Eat the error because different versions of SQLite might have different journal files
                            let _ = try? fm.removeItem(at: storeURL.appendingPathComponent("-shm"))
                            let _ = try? fm.removeItem(at: storeURL.appendingPathComponent("-wal"))
                        }
                    }
                } catch let resetError {
                    callbackQueue.async {
                        callback(.failure(resetError))
                    }
                    return
                }

                // Setup a new stack
                NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(mom, storeFileURL: storeURL) { result in
                    switch result {
                    case .success (let coordinator):
                        self.persistentStoreCoordinator = coordinator
                        callbackQueue.async {
                            callback(.success)
                        }

                    case .failure (let error):
                        callbackQueue.async {
                            callback(.failure(error))
                        }
                    }
                }
            }
        }
    }
}

public extension CoreDataStack {
    /**
     Returns a new `NSManagedObjectContext` as a child of the main queue context.

     Calling `save()` on this managed object context will automatically trigger a save on its parent context via `NSNotification` observing.

     - parameter type: The NSManagedObjectContextConcurrencyType of the new context.
     **Note** this function will trap on a preconditionFailure if you attempt to create a MainQueueConcurrencyType context from a background thread.
     Default value is .PrivateQueueConcurrencyType
     - parameter name: A name for the new context for debugging purposes. Defaults to *Main Queue Context Child*

     - returns: `NSManagedObjectContext` The new worker context.
     */
    public func newChildContext(type: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType,
                                name: String? = "Main Queue Context Child") -> NSManagedObjectContext {
        if type == .mainQueueConcurrencyType && !Thread.isMainThread {
            preconditionFailure("Main thread MOCs must be created on the main thread")
        }

        let moc = NSManagedObjectContext(concurrencyType: type)
        moc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        moc.parent = mainQueueContext
        moc.name = name

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stackMemberContextDidSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: moc)
        return moc
    }

    /**
     Creates a new background `NSManagedObjectContext` connected to
     a discrete `NSPersistentStoreCoordinator` created with the same store used by the stack in construction.

     - parameter on: Optional GCD queue that will be used to dispatch your callback closure. Defaults to background queue used to create the stack.
     - parameter callback: A callback with either the new `NSManagedObjectContext` or an `ErrorType` value with the error
     */
    public func newBatchOperationContext(on callbackQueue: DispatchQueue? = nil, callback: @escaping BatchContextCallback) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        moc.name = "Batch Operation Context"

        switch storeType {
        case .inMemory:
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            do {
                try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
                moc.persistentStoreCoordinator = coordinator
                callback(.success(moc))
            } catch {
                callback(.failure(error))
            }
        case .sqLite(let storeURL):
            let backgroundQueue = DispatchQueue.global(qos: .background)
            let callbackQueue: DispatchQueue = callbackQueue ?? backgroundQueue
            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { result in
                switch result {
                case .success(let coordinator):
                    moc.persistentStoreCoordinator = coordinator
                    callbackQueue.async {
                        callback(.success(moc))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        callback(.failure(error))
                    }
                }
            }
        }
    }
}

fileprivate extension CoreDataStack {
    @objc fileprivate func stackMemberContextDidSaveNotification(_ notification: Notification) {
        guard let notificationMOC = notification.object as? NSManagedObjectContext else {
            assertionFailure("Notification posted from an object other than an NSManagedObjectContext")
            return
        }
        guard let parentContext = notificationMOC.parent else {
            return
        }

        saveBubbleDispatchGroup.enter()
        parentContext.saveContext() { _ in
            self.saveBubbleDispatchGroup.leave()
        }
    }
}

fileprivate extension CoreDataStack {
    fileprivate static var documentsDirectory: URL? {
        get {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls.first
        }
    }
}
