//
//  ModelMigrationTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 8/13/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class ModelMigrationTests: TempDirectoryTestCase {

    func testVersionMigration() throws {
        weak var ex1 = expectation(description: "Setup Expectation")
        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: tempStoreURL) { result in
            switch result {
            case .success(let stack):
                XCTAssertNotNil(stack.mainQueueContext)
            case .failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            ex1?.fulfill()
        }
        waitForExpectations(timeout: 20, handler: nil)
    }

}
