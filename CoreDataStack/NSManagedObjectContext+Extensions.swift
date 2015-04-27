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
    public func saveContextAndWait(error: NSErrorPointer) -> Bool {
        var success = true
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            success = sharedSaveFlow(error)
        case .MainQueueConcurrencyType:
            fallthrough
        case .PrivateQueueConcurrencyType:
            self.performBlockAndWait { [unowned self] in
                success = self.sharedSaveFlow(error)
            }
        }

        return success
    }

    public func saveContext(completion: CoreDataSaveCompletion? = nil) {
        var error: NSError?
        var success: Bool = true
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            success = sharedSaveFlow(&error)
            completion?(success, error)
        case .MainQueueConcurrencyType:
            fallthrough
        case .PrivateQueueConcurrencyType:
            self.performBlock { [unowned self] in
                success = self.sharedSaveFlow(&error)
                completion?(success, error)
            }
        }
    }

    private func sharedSaveFlow(error: NSErrorPointer) -> Bool {
        var success = true
        if self.hasChanges && !self.save(error) {
            success = false
            println("Failed to save managed object context")
            if let error = error.memory {
                println("Error: \(error)")
            }
        }
        return success
    }
}
