//
//  NestedContextStackTests.swift
//  NestedContextStackTests
//
//  Created by Robert Edwards on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreDataStack

class CoreDataStackTests: XCTestCase {

    var stack: CoreDataStack!
    var memoryStore: CoreDataStack!

    override func setUp() {
        super.setUp()

        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")
        CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }

        let ex2 = expectationWithDescription("In Memory Callback")
        CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle, ofStoreType: .InMemory) { result in
            switch result {
            case .Success(let stack):
                self.memoryStore = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex2.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testInitialization() {
        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)

        XCTAssertNotNil(memoryStore.mainQueueContext)
        XCTAssertNotNil(memoryStore.privateQueueContext)
    }

}
