//
//  NSManagedObjectContext+Extensions.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 2/23/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public typealias CoreDataStackSaveCompletion = CoreDataStack.SaveResult -> Void

/**
 Convenience extension to `NSManagedObjectContext` that ensures that saves to contexts of type
 `MainQueueConcurrencyType` and `PrivateQueueConcurrencyType` are dispatched on the correct GCD queue.
*/
public extension NSManagedObjectContext {

    /**
    Convenience method to synchronously save the `NSManagedObjectContext` if changes are present.
    Method also ensures that the save is executed on the correct queue when using Main/Private queue concurrency types.

     - throws: Errors produced by the `save()` function on the `NSManagedObjectContext`
    */
    public func saveContextAndWait() throws {
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            try sharedSaveFlow()
        case .MainQueueConcurrencyType,
             .PrivateQueueConcurrencyType:
            try performAndWaitOrThrow(sharedSaveFlow)
        }
    }

    /**
    Convenience method to asynchronously save the `NSManagedObjectContext` if changes are present.
    Method also ensures that the save is executed on the correct queue when using Main/Private queue concurrency types.

    - parameter completion: Completion closure with a `SaveResult` to be executed upon the completion of the save operation.
    */
    public func saveContext(completion: CoreDataStackSaveCompletion? = nil) {
        func saveFlow() {
            do {
                try sharedSaveFlow()
                completion?(.Success)
            } catch let saveError {
                completion?(.Failure(saveError))
            }
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            saveFlow()
        case .PrivateQueueConcurrencyType,
        .MainQueueConcurrencyType:
            performBlock(saveFlow)
        }
    }

    /**
     Convenience method to synchronously save the `NSManagedObjectContext` if changes are present.
     If any parent contexts are found, they too will be saved synchronously.
     Method also ensures that the save is executed on the correct queue when using Main/Private queue concurrency types.

     - throws: Errors produced by the `save()` function on the `NSManagedObjectContext`
     */
    public func saveContextToStoreAndWait() throws {
        func saveFlow() throws {
            try sharedSaveFlow()
            if let parentContext = parentContext {
                try parentContext.saveContextToStoreAndWait()
            }
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            try saveFlow()
        case .MainQueueConcurrencyType,
             .PrivateQueueConcurrencyType:
            try performAndWaitOrThrow(saveFlow)
        }
    }

    /**
     Convenience method to asynchronously save the `NSManagedObjectContext` if changes are present.
     If any parent contexts are found, they too will be saved asynchronously.
     Method also ensures that the save is executed on the correct queue when using Main/Private queue concurrency types.

    - parameter completion: Completion closure with a `SaveResult` to be executed
        either upon the completion of the top most context's save operation or the first encountered save error.
     */
    public func saveContextToStore(completion: CoreDataStackSaveCompletion? = nil) {
        func saveFlow() {
            do {
                try sharedSaveFlow()
                if let parentContext = parentContext {
                    parentContext.saveContextToStore(completion)
                } else {
                    completion?(.Success)
                }
            } catch let saveError {
                completion?(.Failure(saveError))
            }
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            saveFlow()
        case .PrivateQueueConcurrencyType,
             .MainQueueConcurrencyType:
            performBlock(saveFlow)
        }
    }

    private func sharedSaveFlow() throws {
        guard hasChanges else {
            return
        }

        try save()
    }
}
