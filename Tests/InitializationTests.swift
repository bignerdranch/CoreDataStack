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
        weak var ex1 = expectation(description: "SQLite Callback")

        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: tempStoreURL) { result in
            switch result {
            case .success(let stack):
                self.sqlStack = stack
            case .failure(let error):
                self.failingOn(error)
            }
            ex1?.fulfill()
        }

        do {
            try memoryStack = CoreDataStack.constructInMemoryStack(modelName: "Sample", in: unitTestBundle)
        } catch {
            failingOn(error)
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNotNil(sqlStack.mainQueueContext)
        XCTAssertNotNil(sqlStack.privateQueueContext)

        XCTAssertNotNil(memoryStack.mainQueueContext)
        XCTAssertNotNil(memoryStack.privateQueueContext)
    }

    func testExpectedFailureOfInitializationUsingInvalidURL() {
        weak var ex1 = expectation(description: "SQLite Callback")
        let storeURL = URL(fileURLWithPath: "/store.sqlite")

        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: storeURL) { result in
            switch result {
            case .success(_):
                XCTFail("Constructing with an invalid url should fail")
            case .failure(_):
                break
            }
            ex1?.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNil(sqlStack)
    }
}
