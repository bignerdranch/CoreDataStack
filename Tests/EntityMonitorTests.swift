//
//  EntityMonitorTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

// swiftlint:disable force_try

import XCTest
import CoreData
import CoreDataStack

var insertExpectation: XCTestExpectation!
var deleteExpectation: XCTestExpectation!
var updateExpectation: XCTestExpectation!

class AuthorMonitorDelegate: EntityMonitorDelegate {
    func entityMonitorObservedDeletions(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        deleteExpectation.fulfill()
    }

    func entityMonitorObservedInserts(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        insertExpectation.fulfill()
    }

    func entityMonitorObservedModifications(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
        XCTAssertGreaterThan(entities.count, 0)
        XCTAssertNotNil(entities.first?.firstName)
        updateExpectation.fulfill()
    }
}

class BookMonitorDelegate: EntityMonitorDelegate {
    func entityMonitorObservedDeletions(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
        deleteExpectation.fulfill()
        XCTAssertEqual(entities.count, 1)
    }

    func entityMonitorObservedInserts(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
        XCTFail("Book inserts will never have a matching title so we shouldn't get this callback")
    }

    func entityMonitorObservedModifications(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
        updateExpectation.fulfill()
        XCTAssertEqual(entities.count, 1)
    }
}

class EntityMonitorTests: XCTestCase {

    lazy var model: NSManagedObjectModel = {
        return self.unitTestBundle.managedObjectModel(name: "Container_Example")
    }()
    lazy var container: NSPersistentContainer = {
        return NSPersistentContainer(name: "Container_Example", managedObjectModel: self.model)
    }()
    lazy var authorEntityDescription: NSEntityDescription = {
        return NSEntityDescription.entity(forEntityName: "Author", in: self.container.viewContext)!
    }()
    lazy var bookEntityDescription: NSEntityDescription = {
        return Book.entity()
    }()

    override func setUp() {
        super.setUp()

        weak var setupEx = expectation(description: "Setup")

        continueAfterFailure = false

        let configuration = NSPersistentStoreDescription()
        configuration.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [configuration]

        container.loadPersistentStores() { _, error in
            if let error = error as NSError? {
                XCTFail("Unresolved error \(error), \(error.userInfo)")
            }
            setupEx?.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Insert and save a new item so we can test updates
        let moc = self.container.viewContext
        let fr = NSFetchRequest<Author>()
        fr.entity = authorEntityDescription
        let results = try! moc.fetch(fr)
        if results.count < 1 {
            let _ = Author(context: moc)
            try! moc.saveContextAndWait()
        }
    }

    // MARK: - Tests

    func testOnSaveNotifications() {
        // Setup monitor
        let moc = container.viewContext
        let authorMonitor = EntityMonitor<Author>(context: moc, entity: authorEntityDescription, frequency: .onSave)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        insertExpectation = expectation(description: "EntityMonitor Insert Callback")
        updateExpectation = expectation(description: "EntityMonitor Update Callback")
        deleteExpectation = expectation(description: "EntityMonitor Delete Callback")

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
        moc.delete(entity)
        try! moc.saveContextAndWait()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOnChangeNotifications() {
        // Setup monitor
        let moc = container.viewContext
        let authorMonitor = EntityMonitor<Author>(context: moc, entity: authorEntityDescription, frequency: .onChange)
        let authorMonitorDelegate = AuthorMonitorDelegate()
        authorMonitor.setDelegate(authorMonitorDelegate)

        // Test Insert
        insertExpectation = expectation(description: "EntityMonitor Insert Callback")
        let _ = Author(context: moc)
        waitForExpectations(timeout: 10, handler: nil)

        // New Book (since we aren't observing this shouldn't show up in our delegate callback)
        let _ = Book(context: moc)

        // Test Update
        updateExpectation = expectation(description: "EntityMonitor Update Callback")
        let existing = try! Author.findFirstInContext(moc)!
        existing.firstName = "Robert"
        moc.processPendingChanges()
        waitForExpectations(timeout: 10, handler: nil)

        // Test Delete
        deleteExpectation = expectation(description: "EntityMonitor Delete Callback")
        let deleteMe = Author(context: moc)
        container.viewContext.delete(deleteMe)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFilterPredicate() {
        // Create filter predicate
        let matchingTitle = "nerd"
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", matchingTitle)

        // Setup monitor
        let moc = container.viewContext
        let filteredMonitor = EntityMonitor<Book>(context: moc, entity: bookEntityDescription, filterPredicate: predicate)
        let bookMonitorDelegate = BookMonitorDelegate()
        filteredMonitor.setDelegate(bookMonitorDelegate)

        // Create an initial book
        let newBook = Book(context: moc)
        try! moc.saveContextAndWait()

        // Look for an update
        updateExpectation = expectation(description: "EntityMonitor Update Callback")
        newBook.title = "Swift Programming: The Big Nerd Ranch Guide"
        try! moc.saveContextAndWait()
        waitForExpectations(timeout: 10, handler: nil)

        // Look for deletion
        deleteExpectation = expectation(description: "EntityMonitor Delete Callback")
        moc.delete(newBook)
        try! moc.saveContextAndWait()
        waitForExpectations(timeout: 10, handler: nil)
    }
}
