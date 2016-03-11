//
//  NestedContextStackTests.swift
//  NestedContextStackTests
//
//  Created by Robert Edwards on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class InitializationTests: TempDirectoryTestCase {

    var sqlStack: CoreDataStack!
    var memoryStack: CoreDataStack!

    func testInitialization() {
        weak var ex1 = expectationWithDescription("SQLite Callback")

        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlStack = stack
            case .Failure(let error):
                self.failingOn(error)
            }
            ex1?.fulfill()
        }

        do {
            try memoryStack = CoreDataStack.constructInMemoryStack(withModelName: "Sample", inBundle: unitTestBundle)
        } catch {
            failingOn(error)
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNotNil(sqlStack.mainQueueContext)
        XCTAssertNotNil(sqlStack.privateQueueContext)

        XCTAssertNotNil(memoryStack.mainQueueContext)
        XCTAssertNotNil(memoryStack.privateQueueContext)
    }

    func testExpectedFailureOfInitializationUsingInvalidURL() {
        weak var ex1 = expectationWithDescription("SQLite Callback")
        let storeURL = NSURL(fileURLWithPath: "/store.sqlite")
        
        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: storeURL) { result in
            switch result {
            case .Success(_):
                XCTFail("Constructing with an invalid url should fail")
            case .Failure(_):
                break
            }
            ex1?.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNil(sqlStack)
    }
}
