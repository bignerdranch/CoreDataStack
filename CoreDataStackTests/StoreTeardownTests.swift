//
//  StoreTeardownTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/10/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

class StoreTeardownTests: XCTestCase {

    var stack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let expectation = expectationWithDescription("callback")
        stack = CoreDataStack(modelName: "TestModel", inBundle: NSBundle(forClass: CoreDataStackTests.self)) { (success, error) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testPersistentStoreReset() {
        let expectation = expectationWithDescription("callback")
        stack.resetPersistentStoreCoordinator() { (success, error) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
