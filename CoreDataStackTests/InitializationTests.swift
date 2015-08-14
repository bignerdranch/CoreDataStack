//
//  NestedContextStackTests.swift
//  NestedContextStackTests
//
//  Created by Robert Edwards on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData
import CoreDataStack

class CoreDataStackTests: TempDirectoryTestCase {

    var stack: CoreDataStack!
    var memoryStore: CoreDataStack!

    func testInitialization() throws {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")
        try CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle, inDirectoryAtURL: tempDirectory) { result in
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
        try CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle, ofStoreType: .InMemory) { result in
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

        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)

        XCTAssertNotNil(memoryStore.mainQueueContext)
        XCTAssertNotNil(memoryStore.privateQueueContext)
    }

}
