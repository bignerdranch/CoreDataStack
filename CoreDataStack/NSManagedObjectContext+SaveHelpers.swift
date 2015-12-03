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

    private func sharedSaveFlow() throws {
        guard hasChanges else {
            return
        }

        try save()
    }
}
