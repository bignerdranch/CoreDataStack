//
//  StoreTeardownTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/10/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

// swiftlint:disable force_try

import XCTest

import CoreData

@testable import CoreDataStack

class StoreTeardownTests: TempDirectoryTestCase {

    var sqlStack: CoreDataStack!
    var memoryStack: CoreDataStack!

    override func setUp() {
        super.setUp()

        weak var callbackExpectation = self.expectation(description: "callback")
        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: tempStoreURL) { result in
            switch result {
            case .success(let stack):
                self.sqlStack = stack
            case .failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            callbackExpectation?.fulfill()
        }

        memoryStack = try! CoreDataStack.constructInMemoryStack(modelName: "Sample", in: unitTestBundle)

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testPersistentStoreReset() {
        // Insert some fresh objects
        let worker = sqlStack.newChildContext()
        worker.performAndWait() {
            for _ in 0..<100 {
                NSEntityDescription.insertNewObject(forEntityName: "Author", into: worker)
            }
        }

        // Save just the worker context synchronously
        do {
            try worker.saveContextAndWait()
        } catch {
            failingOn(error)
        }

        // The reset function will wait for all changes to bubble up before removing the store file.
        weak var callbackExpectation = expectation(description: "callback")
        expectation(forNotification: NSNotification.Name(rawValue: Notification.Name.NSManagedObjectContextDidSave.rawValue),
                    object: sqlStack.privateQueueContext, handler: nil)

        sqlStack.resetStore() { result in
            switch result {
            case .success:
                // Insert some objects after a reset
                let worker = self.sqlStack.newChildContext()
                worker.performAndWait() {
                    for _ in 0..<100 {
                        NSEntityDescription.insertNewObject(forEntityName: "Author", into: worker)
                    }
                }
                try! worker.saveContextAndWait()

            case .failure(let error):
                self.failingOn(error)
            }
            callbackExpectation?.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testInMemoryReset() {
        // Insert some fresh objects
        let worker = memoryStack.newChildContext()
        worker.performAndWait() {
            for _ in 0..<100 {
                NSEntityDescription.insertNewObject(forEntityName: "Author", into: worker)
            }
        }

        // Save just the worker context synchronously
        do {
            try worker.saveContextAndWait()
        } catch {
            self.failingOn(error)
        }

        // The reset function will wait for all changes to bubble up before removing the store file.
        weak var callbackExpectation = expectation(description: "callback")
        memoryStack.resetStore() { result in
            switch result {
            case .success:
                // Insert some objects after a reset
                let worker = self.sqlStack.newChildContext()
                worker.performAndWait() {
                    for _ in 0..<100 {
                        NSEntityDescription.insertNewObject(forEntityName: "Author", into: worker)
                    }
                }
                do {
                    try worker.saveContextAndWait()
                } catch {
                    self.failingOn(error)
                }
                break
            case .failure(let error):
                self.failingOn(error)
            }
            callbackExpectation?.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
