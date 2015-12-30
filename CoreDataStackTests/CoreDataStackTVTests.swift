//
//  CoreDataStackTVTests.swift
//  CoreDataStackTVTests
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreDataStack

class CoreDataStackTVTests: TempDirectoryTestCase {

    var inMemoryStack: CoreDataStack!
    var sqlStack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let bundle = NSBundle(forClass: CoreDataStackTVTests.self)
        let modelName = "TestModel"

        do {
            inMemoryStack = try CoreDataStack.constructInMemoryStack(withModelName: modelName, inBundle: bundle)
        } catch {
            XCTFail("\(error)")
        }

        guard let tempStoreURL = tempStoreURL else {
            XCTFail("Temp Dir not created")
            return
        }

        let ex1 = expectationWithDescription("SQLite Setup")
        CoreDataStack.constructSQLiteStack(withModelName: modelName, inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlStack = stack
            case .Failure(let error):
                XCTFail("\(error)")
            }
            ex1.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testInMemoryInitialization() {
        XCTAssertNotNil(inMemoryStack)
    }

    func testSQLiteInitialization() {
        XCTAssertNotNil(sqlStack)
    }
}
