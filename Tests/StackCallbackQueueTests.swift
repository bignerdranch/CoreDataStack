//
//  StackCallbackQueueTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class StackCallbackQueueTests: TempDirectoryTestCase {

    func testMainQueueCallbackExecution() {
        let setupExpectation = expectationWithDescription("Waiting for setup")

        CoreDataStack.constructSQLiteStack(
            withModelName: "Sample",
            inBundle: unitTestBundle,
            callbackQueue: dispatch_get_main_queue()) { _ in
                XCTAssertTrue(NSThread.isMainThread())
                setupExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDefaultQueueCallbackExecution() {
        let setupExpectation = expectationWithDescription("Waiting for setup")

        CoreDataStack.constructSQLiteStack(
            withModelName: "Sample",
            inBundle: unitTestBundle) { _ in
                XCTAssertFalse(NSThread.isMainThread())
                setupExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMainQueueResetCallbackExecution() {
        let resetExpectation = expectationWithDescription("Waiting for reset")

        CoreDataStack.constructSQLiteStack(
            withModelName: "Sample",
            inBundle: unitTestBundle) { setupResult in
                switch setupResult {
                case .Success(let stack):
                    stack.resetStore(dispatch_get_main_queue()) { _ in
                        XCTAssertTrue(NSThread.isMainThread())
                        resetExpectation.fulfill()
                    }
                case .Failure(let error):
                    self.failingOn(error)
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDefaultBackgroundQueueResetCallbackExecution() {
        let resetExpectation = expectationWithDescription("Waiting for reset")

        CoreDataStack.constructSQLiteStack(
            withModelName: "Sample",
            inBundle: unitTestBundle) { setupResult in
                switch setupResult {
                case .Success(let stack):
                    stack.resetStore() { _ in
                        XCTAssertFalse(NSThread.isMainThread())
                        resetExpectation.fulfill()
                    }
                case .Failure(let error):
                    self.failingOn(error)
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

}
