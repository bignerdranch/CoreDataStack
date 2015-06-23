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

        stack = SharedCoordinatorStack(modelName: "TestModel", inBundle: NSBundle(forClass: SharedCoordinatorStackTests.self))
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Main Context Refresh from Background Context Save

    func testBackgroundObjectCreation() {
        let mainContext = stack.mainContext
        let author = Author.newAuthorInContext(mainContext)
        author.firstName = "Bob"
        try! mainContext.saveContextAndWait()
        let authorID = author.objectID

        let backgroundContext = stack.newBackgroundContext(shouldReceiveUpdates: false)
        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                author.lastName = "Smith"
                try! backgroundContext.saveContextAndWait()
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
        try! mainContext.saveContextAndWait()
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
        try! mainContext.saveContextAndWait()

        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author, lastName = author.lastName {
                XCTAssertEqual(lastName, "Blah", "Last name should have been updated here")
            } else {
                XCTFail()
            }
        }

        // Delete Test

        mainContext.deleteObject(author)
        try! mainContext.saveContextAndWait()

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
        try! mainContext.saveContextAndWait()
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
        try! mainContext.saveContextAndWait()

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
        try! mainContext.saveContextAndWait()

        backgroundContext.performBlockAndWait() {
            if let author = backgroundContext.objectWithID(authorID) as? Author {
                if author.deleted {
                    XCTFail("Object should be delete from main queue but still living in background.")
                }
            }
        }
    }
}
