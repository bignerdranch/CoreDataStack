//
//  NSManagedObjectContext+Extensions.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 2/23/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public typealias CoreDataSaveCompletion = (Bool, NSError?) -> Void

public extension NSManagedObjectContext {
    public func saveContextAndWait() throws {
        var saveError: NSError?
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            do {
                try sharedSaveFlow()
            } catch let error as NSError {
                throw error
            }
        case .MainQueueConcurrencyType,
        .PrivateQueueConcurrencyType:
            self.performBlockAndWait { [unowned self] in
                do {
                    try self.sharedSaveFlow()
                } catch let error as NSError {
                    saveError = error
                } catch {
                    assertionFailure("Need either an error or success.")
                }
            }
        }

        if let saveError = saveError {
            throw saveError
        }
    }

    public func saveContext(completion: CoreDataSaveCompletion? = nil) {
        var error: NSError?
        var success: Bool = true

        let saveFlow: (CoreDataSaveCompletion?) -> () = { [unowned self] completion in
            do {
                try self.sharedSaveFlow()
                success = true
            } catch let saveError as NSError {
                error = saveError
                success = false
            } catch {
                assertionFailure("Need either an error or success.")
            }
            completion?(success, error)
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
            } catch let error as NSError {
                throw error
            }
        }
    }
}
