//
//  ModelMigrationTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 8/13/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class ModelMigrationTests: TempDirectoryTestCase {

    let bundle = NSBundle(forClass: ModelMigrationTests.self)
    
    func testVersionMigration() throws {
        let ex1 = expectationWithDescription("Setup Expectation")
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                XCTAssertNotNil(stack.mainQueueContext)
            case .Failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            ex1.fulfill()
        }
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
}
