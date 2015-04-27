//
//  ThreadConfinedStackTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/27/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreDataStack

class ThreadConfinedStackTests: XCTestCase {

    // MARK: - Properties

    lazy var stack = {
        return ThreadConfinementStack(modelName: "TestModel", inBundle: NSBundle(forClass: CoreDataStackTests.self))
        }()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        stack.resetPersistantStoreCoordinator()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Tests

    func testBackgroundObjectCreation() {
        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        backgroundContext.performBlockAndWait() {
            let author = Author.newAuthorInContext(backgroundContext)
            author.firstName = "John"
            author.lastName = "Smith"
            var error: NSError?
            let success = backgroundContext.saveContextAndWait(&error)
            XCTAssertTrue(success)
            XCTAssertNil(error)
        }

        let mainContext = stack.mainContext
        XCTAssertNotNil(mainContext)
        let authors = Author.allAuthorsInContext(mainContext)
        XCTAssertEqual(authors.count, 1)
    }
}
