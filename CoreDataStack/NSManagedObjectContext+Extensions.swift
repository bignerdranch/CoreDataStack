//
//  NSManagedObjectContext+Extensions.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 2/23/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public extension NSManagedObjectContext {
    public func saveContextAndWait() -> Bool {
        var success = true

        let sharedSaveFlow: () -> Bool = {
            var saveError: NSError?
            if self.hasChanges && !self.save(&saveError) {
                success = false
                println("Failed to save managed object context")
                if let error = saveError {
                    println("Error: \(saveError)")
                }
            }
            return success
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            success = sharedSaveFlow()
        case .MainQueueConcurrencyType:
            fallthrough
        case .PrivateQueueConcurrencyType:
            self.performBlockAndWait { [unowned self] in
                success = sharedSaveFlow()
            }
        }

        return success
    }

    public func saveContext() {
        let sharedSaveFlow: () -> () = {
            var saveError: NSError?
            if self.hasChanges && !self.save(&saveError) {
                println("Failed to save managed object context")
                if let error = saveError {
                    println("Error: \(saveError)")
                }
            }
        }

        switch concurrencyType {
        case .ConfinementConcurrencyType:
            sharedSaveFlow()
        case .MainQueueConcurrencyType:
            fallthrough
        case .PrivateQueueConcurrencyType:
            self.performBlock { [unowned self] in
                sharedSaveFlow()
            }
        }
    }
}
