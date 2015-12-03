//
//  NSPersistentStoreCoordinator+AsyncHelpers.swift
//  CoreDataStack
//
//  Created by Zachary Waldowski on 12/2/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

extension NSPersistentStoreCoordinator {
    /**
     Synchronously exexcutes a given function on the coordinator's internal
     queue.

     This method may safely be called reentrantly.
    **/
    public func performAndWaitOrThrow<Return>(body: () throws -> Return) throws -> Return {
        var result: Return!
        var thrown: ErrorType?

        performBlockAndWait {
            do {
                result = try body()
            } catch {
                thrown = error
            }
        }

        if let thrown = thrown {
            throw thrown
        } else {
            return result
        }
    }
}
