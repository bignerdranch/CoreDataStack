//
//  NSPersistentStoreCoordinator+AsyncHelpers.swift
//  CoreDataStack
//
//  Created by Zachary Waldowski on 12/2/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import CoreData

extension NSPersistentStoreCoordinator {
    /**
     Synchronously exexcutes a given function on the coordinator's internal
     queue.

     - attention: This method may safely be called reentrantly.
     - parameter body: The method body to perform on the reciever.
     - returns: The value returned from the inner function.
     - throws: Any error thrown by the inner function. This method should be
     technically `rethrows`, but cannot be due to Swift limitations.
    **/
    public func performAndWaitOrThrow<Return>(_ body: () throws -> Return) rethrows -> Return {
        func impl(execute work: () throws -> Return, recover: (Error) throws -> Void) rethrows -> Return {
            var result: Return!
            var error: Error?

            // performAndWait is marked @escaping as of iOS 10.0.
            typealias Fn = (() -> Void) -> Void
            let performAndWaitNoescape = unsafeBitCast(self.performAndWait, to: Fn.self)
            performAndWaitNoescape {
                do {
                    result = try work()
                } catch let e {
                    error = e
                }
            }

            if let error = error {
                try recover(error)
            }

            return result
        }

        return try impl(execute: body, recover: { throw $0 })
    }
}
