//
//  ModelMigrationTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 8/13/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

class ModelMigrationTests: XCTestCase {

    let bundle = NSBundle(forClass: ModelMigrationTests.self)
    override func setUp() {
        super.setUp()

        let existingModelURL = bundle.URLForResource("TestModel", withExtension: "sqlite")!

        let destinationURL = NSPersistentStoreCoordinator.urlForSQLiteStore(modelName: "TestModel")
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(destinationURL.path!) {
            try! fileManager.removeItemAtURL(destinationURL)
        }
        try! NSFileManager.defaultManager().copyItemAtURL(existingModelURL, toURL: destinationURL)
    }
    
    func testVersionMigration() {
        let ex1 = expectationWithDescription("Setup Expectation")
        CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle, ofStoreType: .SQLite) { result in
            switch result {
            case .Success(let stack):
                XCTAssertNotNil(stack.mainQueueContext)
            case .Failure(let error):
                XCTFail("\(error)")
            }
            ex1.fulfill()
        }
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
}
