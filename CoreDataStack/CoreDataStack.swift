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
public enum SetupResult {
    case Success(NSPersistentStoreCoordinator)
    case Failure(NSError)
}
public typealias CoreDataSetupCallback = (success: Bool, error: NSError?) -> Void

/**
Three layer CoreData stack comprised of:

* A primary background queue context with a persistent store coordinator
* A main queue context that is a child of the primary queue
* A method for spawning many background worker contexts that are children of the main queue context

Calling save() on any NSMangedObject context, belonging to the stack, will automatically bubble the changes all the way to the NSPersistentStore
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

    /**
    Primary persisting background managed object context. This is the top level context that possess an
    NSPersistentStoreCoordinator and saves changes to disk on a background queue.

    Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.

    NSBatchUpdateRequest and NSAsynchronousFetchRequest require a context with a persistent store connected directly,
    if this was not the case this context would be marked private.

    - returns: NSManagedObjectContext The primary persisting background context.
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

    - returns: NSManagedObjectContext The main queue context.
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

    // MARK: - Lifecycle

    /**
    Creates a SQLite backed CoreData stack for a give model in the supplyed NSBundle.

    - parameter modelName: Name of the xcdatamodel for the CoreData Stack.
    - parameter inBundle: NSBundle that contains the XCDataModel. Default value is mainBundle()
    - parameter callback: The persistent store cooridiator will be setup asynchronously. This callback serves as notificaton that your stack is fully intialized. _Important_ access to this class is not safe until after this callback has fired.

    - returns: CoreDataStack Newly created stack.
    */
    public required init(modelName: String, inBundle: NSBundle = NSBundle.mainBundle(), callback: CoreDataSetupCallback) {
        bundle = inBundle
        managedObjectModelName = modelName

        super.init()

        NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: NSPersistentStoreCoordinator.urlForSQLiteStore(modelName: managedObjectModelName)) { (result) in
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
    
    - parameter modelName: Name of the xcdatamodel for the CoreData Stack.
    - parameter inBundle: NSBundle that contains the XCDataModel. Default value is mainBundle()
    
    - returns: CoreDataStack Newly created stack.
    */
    public required init(inMemoryStoreWithModelName modelName: String, inBundle: NSBundle = NSBundle.mainBundle()) {
        bundle = inBundle
        managedObjectModelName = modelName

        super.init()

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        try! persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
    }

    // MARK: - Public Functions

    /**
    Removes the SQLite store from disk and creates a fresh NSPersistentStore.
    */
    public func resetPersistentStoreCoordinator(setupCallback: CoreDataSetupCallback) {
        do {
            if #available(iOS 9, *), let store = persistentStoreCoordinator.persistentStoreForURL(storeURL) {
                try persistentStoreCoordinator.removePersistentStore(store)
            } else {
                persistentStoreCoordinator = nil
                try NSFileManager.defaultManager().removeItemAtURL(storeURL)
            }

            NSPersistentStoreCoordinator.setupSQLiteBackedCoordinator(managedObjectModel, storeFileURL: storeURL) { (result: SetupResult) in
                switch result {
                case .Success (let coordinator):
                    self.persistentStoreCoordinator = coordinator
                    setupCallback(success: true, error: nil)
                case .Failure (let error):
                    setupCallback(success: false, error: error)
                }
            }
        } catch let fileRemoveError as NSError {
            setupCallback(success: false, error: fileRemoveError)
        }
    }

    // MARK: - Saving

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
