//
//  NSManagedObjectContext+Extensions.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 2/23/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public typealias CoreDataStackSaveCompletion = SaveResult -> Void

public extension NSManagedObjectContext {
    public func saveContextAndWait() throws {
        var saveError: ErrorType?
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            do {
                try sharedSaveFlow()
            } catch let error {
                throw error
            }
        case .MainQueueConcurrencyType,
        .PrivateQueueConcurrencyType:
            self.performBlockAndWait { [unowned self] in
                do {
                    try self.sharedSaveFlow()
                } catch let error {
                    saveError = error
                }
            }
        }

        if let saveError = saveError {
            throw saveError
        }
    }

    public func saveContext(completion: CoreDataStackSaveCompletion? = nil) {
        let saveFlow: (CoreDataStackSaveCompletion?) -> () = { [unowned self] completion in
            do {
                try self.sharedSaveFlow()
                completion?(.Success)
            } catch let saveError {
                completion?(.Failure(saveError))
            }
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            saveFlow(completion)
        case .PrivateQueueConcurrencyType,
        .MainQueueConcurrencyType:
            self.performBlock {
                saveFlow(completion)
            }
        }
    }

    private func sharedSaveFlow() throws {
        if hasChanges {
            do {
                try save()
            } catch let error {
                throw error
            }
        }
    }
}
