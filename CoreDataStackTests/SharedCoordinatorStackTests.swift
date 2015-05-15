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
        let authorID = author.objectID

        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
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
        let authorID = author.objectID

        //Update Test

        backgroundContext.performBlockAndWait {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                author.firstName = "Joe"
            } else {
                XCTFail()
            }
        }

        author.lastName = "Blah"
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author, lastName = author.lastName {
                XCTAssertEqual(lastName, "Blah", "Last name should have been updated here")
            } else {
                XCTFail()
            }
        }

        // Delete Test

        mainContext.deleteObject(author)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                if !author.deleted {
                    XCTFail("Author object should have been removed here also.")
                }
            }
        }
    }

    func testIgnoringMainContextChanges() {
        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        let mainContext = stack.mainContext

        let author = Author.newAuthorInContext(mainContext)
        XCTAssertTrue(mainContext.saveContextAndWait(nil))
        let authorID = author.objectID

        // Update Test

        backgroundContext.performBlockAndWait {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                author.firstName = "Joe"
            } else {
                XCTFail()
            }
        }

        author.lastName = "Blah"
        XCTAssertTrue(mainContext.saveContextAndWait(nil))

        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
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
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                if author.deleted {
                    XCTFail("Object should be delete from main queue but still living in background.")
                }
            }
        }
    }
}
