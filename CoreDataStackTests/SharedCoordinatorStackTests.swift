//
//  SharedCoordinatorStackTests.swift
//  SharedCoordinatorStackTests
//
//  Created by Robert Edwards on 4/27/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreDataStack
import CoreData

class SharedCoordinatorStackTests: XCTestCase {

    // MARK: - Properties

    var stack: SharedCoordinatorStack!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        let storeURL = NSPersistentStoreCoordinator.urlForSQLiteStore(modelName: "TestModel")
        let path = storeURL.path!
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            var error: NSError?
            if !NSFileManager.defaultManager().removeItemAtURL(storeURL, error: &error) {
                println(error)
                XCTFail("Failed to remove store")
            }
        }
        
        let ex1 = expectationWithDescription("callback")
        stack = SharedCoordinatorStack(modelName: "TestModel", inBundle: NSBundle(forClass: SharedCoordinatorStackTests.self)) { (success, error) in
            XCTAssertTrue(success)
            ex1.fulfill()
        }



        waitForExpectationsWithTimeout(10, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Main Context Refresh from Background Context Save

    func testBackgroundObjectCreation() {
        let mainContext = stack.mainContext
        let author = Author.newAuthorInContext(mainContext)
        author.firstName = "Bob"
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        backgroundContext.performBlockAndWait() {
            if let author = Author.allAuthorsInContext(backgroundContext).first {
                author.lastName = "Smith"
                XCTAssertTrue(backgroundContext.saveContextAndWait(nil))
            } else {
                XCTFail()
            }
        }

        if let lastName = author.lastName {
            XCTAssertEqual(lastName, "Smith")
        } else {
            XCTFail()
        }
    }

    // MARK: - Background Context Refresh from Main Context Save

    func testReceivingUpdatesFromMainContext() {
        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: true)
        let mainContext = stack.mainContext

        let author = Author.newAuthorInContext(mainContext)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        //Update Test

        backgroundContext.performBlockAndWait {
            if let author = Author.allAuthorsInContext(backgroundContext).first {
                author.firstName = "Joe"
            } else {
                XCTFail()
            }
        }

        author.lastName = "Blah"
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            if let author = Author.allAuthorsInContext(backgroundContext).first, lastName = author.lastName {
                XCTAssertEqual(lastName, "Blah", "Last name should have been updated here")
            } else {
                XCTFail()
            }
        }

        // Delete Test

        mainContext.deleteObject(author)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            XCTAssertEqual(Author.allAuthorsInContext(backgroundContext).count, 0,
            "Author object should have been removed here also.")
        }
    }

    func testIgnoringMainContextChanges() {
        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        let mainContext = stack.mainContext

        let author = Author.newAuthorInContext(mainContext)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        // Update Test

        backgroundContext.performBlockAndWait {
            if let author = Author.allAuthorsInContext(backgroundContext).first {
                author.firstName = "Joe"
            } else {
                XCTFail()
            }
        }

        author.lastName = "Blah"
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            if let author = Author.allAuthorsInContext(backgroundContext).first {
                XCTAssertNil(author.lastName,
                    "Last name shouldn't have been propegated from main queue")
            } else {
                XCTFail()
            }

        }

        // Delete Test
        
        mainContext.deleteObject(author)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            XCTAssertEqual(Author.allAuthorsInContext(backgroundContext).count, 1,
                "Object should be delete from main queue but still living in background.")
        }
    }
}
