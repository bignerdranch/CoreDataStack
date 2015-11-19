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

class EntityMonitorTests: TempDirectoryTestCase, EntityMonitorDelegate {

    var stack: CoreDataStack!
    var monitor: EntityMonitor<Author>!
    var filteredMonitor: EntityMonitor<Author>!

    var insertExpectation: XCTestExpectation!
    var deleteExpectation: XCTestExpectation!
    var updateExpectation: XCTestExpectation!

    override func setUp() {
        super.setUp()

        let setupEx = expectationWithDescription("Setup")
        let bundle = NSBundle(forClass: CoreDataStackTests.self)

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
        monitor = EntityMonitor<Author>(context: moc, frequency: .OnSave)
        monitor.setDelegate(self)

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
        let existing = Author.findFirst(nil, context: moc)!
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
        monitor = EntityMonitor<Author>(context: moc, frequency: .OnChange)
        monitor.setDelegate(self)

        // Test Insert
        insertExpectation = expectationWithDescription("EntityMonitor Insert Callback")
        let _ = Author(managedObjectContext: moc)
        waitForExpectationsWithTimeout(10, handler: nil)

        // New Book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(managedObjectContext: moc)

        // Test Update
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        let existing = Author.findFirst(nil, context: moc)!
        existing.setValue("Robert", forKey: "firstName")
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
        let matchingLastName = "Edwards"
        let predicate = NSPredicate(format: "lastName = %@", matchingLastName)

        // Setup monitor
        let moc = stack.mainQueueContext
        filteredMonitor = EntityMonitor<Author>(context: moc, filterPredicate: predicate)
        filteredMonitor.setDelegate(self)

        // Create an initial book
        let newAuthor = Author(managedObjectContext: moc)
        try! moc.saveContextAndWait()

        // Look for an update
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        newAuthor.lastName = matchingLastName
        try! moc.saveContextAndWait()
        waitForExpectationsWithTimeout(10, handler: nil)

        // Look for deletion
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")
        moc.deleteObject(newAuthor)
        try! moc.saveContextAndWait()
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // MARK: - EntityMonitorDelegate

    // Author Monitor

    func entityMonitorObservedDeletions(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        if monitor === self.monitor {
            XCTAssertGreaterThan(entities.count, 0)
            deleteExpectation.fulfill()
        } else if monitor === filteredMonitor {
            deleteExpectation.fulfill()
            XCTAssertEqual(entities.count, 1)
        }
    }

    func entityMonitorObservedInserts(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        if monitor === self.monitor {
            XCTAssertGreaterThan(entities.count, 0)
            insertExpectation.fulfill()
        } else if monitor === self.filteredMonitor {
            XCTFail("Book inserts will never have a matching title so we shouldn't get this callback")
        }
    }

    func entityMonitorObservedModifications(monitor: EntityMonitor<Author>, entities: Set<Author>) {
        if monitor === self.monitor {
            XCTAssertGreaterThan(entities.count, 0)
            XCTAssertNotNil(entities.first?.firstName)
            updateExpectation.fulfill()
        } else if monitor === self.filteredMonitor {
            updateExpectation.fulfill()
            XCTAssertEqual(entities.count, 1)
        }
    }
}
