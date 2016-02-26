//
//  NSManagedObjectContext+AsyncHelpers.swift
//  CoreDataStack
//
//  Created by Zachary Waldowski on 12/2/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData
import Swift

extension NSManagedObjectContext {
    /**
     Synchronously exexcutes a given function on the receiver’s queue.

     You use this method to safely address managed objects on a concurrent
     queue.
     
     - attention: This method may safely be called reentrantly.
     - parameter body: The method body to perform on the reciever.
     - returns: The value returned from the inner function.
     - throws: Any error thrown by the inner function. This method should be
       technically `rethrows`, but cannot be due to Swift limitations.
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
