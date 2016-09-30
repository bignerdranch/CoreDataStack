//
//  CoreDataStackTVTests.swift
//  CoreDataStackTVTests
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
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
            inMemoryStack = try CoreDataStack.constructInMemoryStack(modelName: modelName, in: unitTestBundle)
        } catch {
            failingOn(error)
        }

        guard let tempStoreURL = tempStoreURL else {
            XCTFail("Temp Dir not created")
            return
        }

        weak var ex1 = expectation(description: "SQLite Setup")
        CoreDataStack.constructSQLiteStack(modelName: modelName, in: unitTestBundle, at: tempStoreURL) { result in
            switch result {
            case .success(let stack):
                self.sqlStack = stack
            case .failure(let error):
                self.failingOn(error)
            }
            ex1?.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testInMemoryInitialization() {
        XCTAssertNotNil(inMemoryStack)
    }

    func testSQLiteInitialization() {
        XCTAssertNotNil(sqlStack)
    }
}
