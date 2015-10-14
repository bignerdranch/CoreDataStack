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

class CoreDataStackTests: TempDirectoryTestCase {

    var stack: CoreDataStack!
    var memoryStore: CoreDataStack!

    func testInitialization() throws {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")

        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }

        do {
            try stack = CoreDataStack.constructInMemoryStack(withModelName: "TestModel", inBundle: bundle)
        } catch {
            XCTFail("\(error)")
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)

        XCTAssertNotNil(memoryStore.mainQueueContext)
        XCTAssertNotNil(memoryStore.privateQueueContext)
    }

}
