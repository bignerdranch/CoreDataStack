//
//  StackCallbackQueueTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/21/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class StackCallbackQueueTests: TempDirectoryTestCase {

    func testMainQueueCallbackExecution() {
        let setupExpectation = expectation(description: "Waiting for setup")

        CoreDataStack.constructSQLiteStack(modelName: "Sample",
                                           in: unitTestBundle,
                                           on: DispatchQueue.main) { _ in
                                            XCTAssertTrue(Thread.isMainThread)
                                            setupExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDefaultQueueCallbackExecution() {
        let setupExpectation = expectation(description: "Waiting for setup")

        CoreDataStack.constructSQLiteStack(
            modelName: "Sample",
            in: unitTestBundle) { _ in
                XCTAssertFalse(Thread.isMainThread)
                setupExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testMainQueueResetCallbackExecution() {
        let resetExpectation = expectation(description: "Waiting for reset")

        CoreDataStack.constructSQLiteStack(
            modelName: "Sample",
            in: unitTestBundle) { setupResult in
                switch setupResult {
                case .success(let stack):
                    stack.resetStore(on: DispatchQueue.main) { _ in
                        XCTAssertTrue(Thread.isMainThread)
                        resetExpectation.fulfill()
                    }
                case .failure(let error):
                    self.failingOn(error)
                }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDefaultBackgroundQueueResetCallbackExecution() {
        let resetExpectation = expectation(description: "Waiting for reset")

        CoreDataStack.constructSQLiteStack(
            modelName: "Sample",
            in: unitTestBundle) { setupResult in
                switch setupResult {
                case .success(let stack):
                    stack.resetStore() { _ in
                        XCTAssertFalse(Thread.isMainThread)
                        resetExpectation.fulfill()
                    }
                case .failure(let error):
                    self.failingOn(error)
                }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

}
