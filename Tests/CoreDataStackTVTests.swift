//
//  CoreDataStackTVTests.swift
//  CoreDataStackTVTests
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackTVTests: TempDirectoryTestCase {

    var inMemoryStack: CoreDataStack!
    var sqlStack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let modelName = "Sample"

        do {
            inMemoryStack = try CoreDataStack.constructInMemoryStack(withModelName: modelName, inBundle: unitTestBundle)
        } catch {
            XCTFail("\(error)")
        }

        guard let tempStoreURL = tempStoreURL else {
            XCTFail("Temp Dir not created")
            return
        }

        weak var ex1 = expectationWithDescription("SQLite Setup")
        CoreDataStack.constructSQLiteStack(withModelName: modelName, inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlStack = stack
            case .Failure(let error):
                XCTFail("\(error)")
            }
            ex1?.fulfill()
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
