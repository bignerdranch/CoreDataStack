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

class EntityMonitorTests: XCTestCase {
    lazy var model: NSManagedObjectModel = {
        return self.unitTestBundle.managedObjectModel("Container_Example")
    }()
    lazy var container: NSPersistentContainer = {
        return NSPersistentContainer(name: "Container_Example", managedObjectModel: self.model)
    }()

    override func setUp() {
        super.setUp()

        weak var setupEx = expectationWithDescription("Setup")

        continueAfterFailure = false

        let configuration = NSPersistentStoreDescription()
        configuration.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [configuration]

        container.loadPersistentStoresWithCompletionHandler() { storeDescription, error in
            if let error = error {
                XCTFail("Unresolved error \(error), \(error.userInfo)")
            }
            setupEx?.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        let moc = container.viewContext

        // Insert and save a new item so we can test updates
        let fr = NSFetchRequest()
        fr.entity = NSEntityDescription.entityForName("Author", inManagedObjectContext: moc)!
        let results = try! moc.executeFetchRequest(fr)
        if results.count < 1 {
            let _ = Author(context: container.viewContext)
            try! moc.saveContextAndWait()
        }
    }

    // MARK: - Tests

    func testOnSaveNotifications() {
        // Setup monitor
        let moc = container.viewContext
        let entityDescription = NSEntityDescription.entityForName("Author", inManagedObjectContext: moc)!
        let authorMonitor = EntityMonitor<Author>(context: moc, entity: entityDescription, frequency: .OnSave)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        insertExpectation = expectationWithDescription("EntityMonitor Insert Callback")
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")

        // Insert an Item
        let entity = Author(context: moc)
        try! moc.saveContextAndWait()

        // New book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(context: moc)
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
        let moc = container.viewContext
        let entity = NSEntityDescription.entityForName("Author", inManagedObjectContext: moc)!
        let authorMonitor = EntityMonitor<Author>(context: moc, entity: entity, frequency: .OnChange)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        // Test Insert
        insertExpectation = expectationWithDescription("EntityMonitor Insert Callback")
        let _ = Author(context: moc)
        waitForExpectationsWithTimeout(10, handler: nil)

        // New Book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(context: moc)

        // Test Update
        updateExpectation = expectationWithDescription("EntityMonitor Update Callback")
        let existing = try! Author.findFirstInContext(moc)!
        existing.firstName = "Robert"
        moc.processPendingChanges()
        waitForExpectationsWithTimeout(10, handler: nil)

        // Test Delete
        deleteExpectation = expectationWithDescription("EntityMonitor Delete Callback")
        let deleteMe = Author(context: moc)
        container.viewContext.deleteObject(deleteMe)
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testFilterPredicate() {
        // Create filter predicate
        let matchingTitle = "nerd"
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", matchingTitle)

        // Setup monitor
        let moc = container.viewContext
        let entity = NSEntityDescription.entityForName("Book", inManagedObjectContext: moc)!
        let filteredMonitor = EntityMonitor<Book>(context: moc, entity: entity, filterPredicate: predicate)
        let bookMonitorDelegate = BookMonitorDelegate()
        filteredMonitor.setDelegate(bookMonitorDelegate)

        // Create an initial book
        let newBook = Book(context: moc)
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
