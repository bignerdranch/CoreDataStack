//
//  StoreTeardownTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/10/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class StoreTeardownTests: TempDirectoryTestCase {

    var sqlStack: CoreDataStack!
    var memoryStack: CoreDataStack!

    override func setUp() {
        super.setUp()

        weak var expectation = expectationWithDescription("callback")
        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlStack = stack
            case .Failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            expectation?.fulfill()
        }

        memoryStack = try! CoreDataStack.constructInMemoryStack(withModelName: "Sample", inBundle: unitTestBundle)

        waitForExpectationsWithTimeout(10, handler: nil)
    }


    func testPersistentStoreReset() {
        // Insert some fresh objects
        let worker = sqlStack.newChildContext()
        worker.performBlockAndWait() {
            for _ in 0..<100 {
                NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: worker)
            }
        }

        // Save just the worker context synchronously
        try! worker.saveContextAndWait()

        // The reset function will wait for all changes to bubble up before removing the store file.
        weak var expectation = expectationWithDescription("callback")
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: sqlStack.privateQueueContext, handler: nil)
        sqlStack.resetStore() { result in
            switch result {
            case .Success:
                // Insert some objects after a reset
                let worker = self.sqlStack.newChildContext()
                worker.performBlockAndWait() {
                    for _ in 0..<100 {
                        NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: worker)
                    }
                }
                try! worker.saveContextAndWait()
                break

            case .Failure(let error):
                self.failingOn(error)
            }
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testInMemoryReset() {
        // Insert some fresh objects
        let worker = memoryStack.newChildContext()
        worker.performBlockAndWait() {
            for _ in 0..<100 {
                NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: worker)
            }
        }

        // Save just the worker context synchronously
        try! worker.saveContextAndWait()

        // The reset function will wait for all changes to bubble up before removing the store file.
        weak var expectation = expectationWithDescription("callback")
        memoryStack.resetStore() { result in
            switch result {
            case .Success:
                // Insert some objects after a reset
                let worker = self.sqlStack.newChildContext()
                worker.performBlockAndWait() {
                    for _ in 0..<100 {
                        NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: worker)
                    }
                }
                try! worker.saveContextAndWait()
                break
            case .Failure(let error):
                self.failingOn(error)
            }
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
