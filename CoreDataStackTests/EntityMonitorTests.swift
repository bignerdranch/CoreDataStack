//
//  EntityMonitorTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest
import CoreData
import CoreDataStack

var insertExpectation: XCTestExpectation!
var deleteExpectation: XCTestExpectation!
var updateExpectation: XCTestExpectation!

class AuthorMonitorDelegate: EntityMonitorDelegate {
    func entityMonitorObservedDeletions(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        deleteExpectation.fulfill()
    }

    func entityMonitorObservedInserts(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        insertExpectation.fulfill()
    }

    func entityMonitorObservedModifications(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        XCTAssertNotNil(entities.first?.firstName)
        updateExpectation.fulfill()
    }
}

class BookMonitorDelegate: EntityMonitorDelegate {
    func entityMonitorObservedDeletions(monitor: EntityMonitor<Book>, entities: Set<Book>) {
        deleteExpectation.fulfill()
        XCTAssertEqual(entities.count, 1)
    }

    func entityMonitorObservedInserts(monitor: EntityMonitor<Book>, entities: Set<Book>) {
        XCTFail("Book inserts will never have a matching title so we shouldn't get this callback")
    }

    func entityMonitorObservedModifications(monitor: EntityMonitor<Book>, entities: Set<Book>) {
        updateExpectation.fulfill()
        XCTAssertEqual(entities.count, 1)
    }
}

class EntityMonitorTests: TempDirectoryTestCase {

    var stack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let setupEx = expectationWithDescription("Setup")
        let bundle = NSBundle(forClass: EntityMonitorTests.self)

        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            setupEx.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        // Insert and save a new item so we can test updates
        let moc = stack.mainQueueContext
        let fr = NSFetchRequest(entityName: Author.entityName)
        let results = try! moc.executeFetchRequest(fr)
        if results.count < 1 {
            let _ = Author(managedObjectContext: stack.mainQueueContext)
            try! moc.saveContextAndWait()
        }
    }

    // MARK: - Tests

    func testOnSaveNotifications() {
        // Setup monitor
        let moc = stack.mainQueueContext
        let authorMonitor = EntityMonitor<Author>(context: moc, frequency: .OnSave)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        insertExpectation = expectationWithDescription("EntityMonitor Insert Callback")
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")

        // Insert an Item
        let entity = Author(managedObjectContext: moc)
        try! moc.saveContextAndWait()

        // New book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(managedObjectContext: moc)
        try! moc.saveContextAndWait()

        // Modify an existing
        let existing = try! Author.findFirstInContext(moc)!
        existing.setValue("Robert", forKey: "firstName")
        moc.saveContext()

        // Delete an item
        moc.deleteObject(entity)
        try! moc.saveContextAndWait()

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testOnChangeNotifications() {
        // Setup monitor
        let moc = stack.mainQueueContext
        let authorMonitor = EntityMonitor<Author>(context: moc, frequency: .OnChange)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        // Test Insert
        insertExpectation = expectationWithDescription("EntityMonitor Insert Callback")
        let _ = Author(managedObjectContext: moc)
        waitForExpectationsWithTimeout(10, handler: nil)

        // New Book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(managedObjectContext: moc)

        // Test Update
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        let existing = try! Author.findFirstInContext(moc)!
        existing.firstName = "Robert"
        moc.processPendingChanges()
        waitForExpectationsWithTimeout(10, handler: nil)

        // Test Delete
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")
        let deleteMe = Author(managedObjectContext: moc)
        stack.mainQueueContext.deleteObject(deleteMe)
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testFilterPredicate() {
        // Create filter predicate
        let matchingTitle = "nerd"
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", matchingTitle)

        // Setup monitor
        let moc = stack.mainQueueContext
        let filteredMonitor = EntityMonitor<Book>(context: moc, filterPredicate: predicate)
        let bookMonitorDelegate = BookMonitorDelegate()
        filteredMonitor.setDelegate(bookMonitorDelegate)

        // Create an initial book
        let newBook = Book(managedObjectContext: moc)
        try! moc.saveContextAndWait()

        // Look for an update
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        newBook.title = "Swift Programming: The Big Nerd Ranch Guide"
        try! moc.saveContextAndWait()
        waitForExpectationsWithTimeout(10, handler: nil)

        // Look for deletion
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")
        moc.deleteObject(newBook)
        try! moc.saveContextAndWait()
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
