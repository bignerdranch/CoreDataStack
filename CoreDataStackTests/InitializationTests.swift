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

        let expectation = expectationWithDescription("callback")
        stack = CoreDataStack(modelName: "TestModel", inBundle: NSBundle(forClass: CoreDataStackTests.self)) { (success, error) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        memoryStore = CoreDataStack(inMemoryStoreWithModelName: "TestModel", inBundle: NSBundle(forClass: CoreDataStackTests.self))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)

        XCTAssertNotNil(memoryStore.mainQueueContext)
        XCTAssertNotNil(memoryStore.privateQueueContext)
    }

}
