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
    let bundle = NSBundle(forClass: InitializationTests.self)

    func testInitialization() {
        let ex1 = expectationWithDescription("SQLite Callback")

        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlStack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }

        do {
            try memoryStack = CoreDataStack.constructInMemoryStack(withModelName: "TestModel", inBundle: bundle)
        } catch {
            XCTFail("\(error)")
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNotNil(sqlStack.mainQueueContext)
        XCTAssertNotNil(sqlStack.privateQueueContext)

        XCTAssertNotNil(memoryStack.mainQueueContext)
        XCTAssertNotNil(memoryStack.privateQueueContext)
    }

    func testInitializationWithInvalidStoreURL() {
        let ex1 = expectationWithDescription("SQLite Callback")
        let storeURL = NSURL(fileURLWithPath: "/store.sqlite")
        
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: storeURL) { result in
            switch result {
            case .Success(_):
                XCTFail()
            case .Failure(let error):
                print(error)
            }
            ex1.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNil(sqlStack)
    }
}
