////
////  EntityMonitorTests.swift
////  CoreDataStack
////
////  Created by Robert Edwards on 11/18/15.
////  Copyright © 2015 Big Nerd Ranch. All rights reserved.
////
//
//import XCTest
//import CoreData
//import CoreDataStack
//
//var insertExpectation: XCTestExpectation!
//var deleteExpectation: XCTestExpectation!
//var updateExpectation: XCTestExpectation!
//
//class AuthorMonitorDelegate: EntityMonitorDelegate {
//    func entityMonitorObservedDeletions(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
//        XCTAssertGreaterThan(entities.count, 0)
//        deleteExpectation.fulfill()
//    }
//
//    func entityMonitorObservedInserts(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
//        XCTAssertGreaterThan(entities.count, 0)
//        insertExpectation.fulfill()
//    }
//
//    func entityMonitorObservedModifications(_ monitor: EntityMonitor<Author>, entities: Set<Author>) {
//        XCTAssertGreaterThan(entities.count, 0)
//        XCTAssertNotNil(entities.first?.firstName)
//        updateExpectation.fulfill()
//    }
//}
//
//class BookMonitorDelegate: EntityMonitorDelegate {
//    func entityMonitorObservedDeletions(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
//        deleteExpectation.fulfill()
//        XCTAssertEqual(entities.count, 1)
//    }
//
//    func entityMonitorObservedInserts(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
//        XCTFail("Book inserts will never have a matching title so we shouldn't get this callback")
//    }
//
//    func entityMonitorObservedModifications(_ monitor: EntityMonitor<Book>, entities: Set<Book>) {
//        updateExpectation.fulfill()
//        XCTAssertEqual(entities.count, 1)
//    }
//}
//
//class EntityMonitorTests: TempDirectoryTestCase {
//
//    var stack: CoreDataStack!
//
//    override func setUp() {
//        super.setUp()
//
//        weak var setupEx = expectation(withDescription: "Setup")
//
//        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
//            switch result {
//            case .success(let stack):
//                self.stack = stack
//            case .failure(let error):
//                self.failingOn(error)
//            }
//            setupEx?.fulfill()
//        }
//
//        waitForExpectations(withTimeout: 10, handler: nil)
//
//        // Insert and save a new item so we can test updates
//        let moc = stack.mainQueueContext
//        let fr = NSFetchRequest(entityName: Author.entityName)
//        let results = try! moc.executeFetchRequest(fr)
//        if results.count < 1 {
//            let _ = Author(context: stack.mainQueueContext)
//            try! moc.saveContextAndWait()
//        }
//    }
//
//    // MARK: - Tests
//
//    func testOnSaveNotifications() {
//        // Setup monitor
//        let moc = stack.mainQueueContext
//        let authorMonitor = EntityMonitor<Author>(context: moc, frequency: .OnSave)
//        let authorMonitorDelegate = AuthorMonitorDelegate()
//        authorMonitor.setDelegate(authorMonitorDelegate)
//
//        insertExpectation = expectation(withDescription: "EntityMonitor Insert Callback")
//        updateExpectation = expectation(withDescription: "EntityMonitor Update Callback")
//        deleteExpectation = expectation(withDescription: "EntityMonitor Delete Callback")
//
//        // Insert an Item
//        let entity = Author(managedObjectContext: moc)
//        try! moc.saveContextAndWait()
//
//        // New book (since we aren't observing this shouldn't show up in our delegate callback)
//        let _ = Book(managedObjectContext: moc)
//        try! moc.saveContextAndWait()
//
//        // Modify an existing
//        let existing = try! Author.findFirstInContext(moc)!
//        existing.setValue("Robert", forKey: "firstName")
//        moc.saveContext()
//
//        // Delete an item
//        moc.deleteObject(entity)
//        try! moc.saveContextAndWait()
//
//        waitForExpectations(withTimeout: 10, handler: nil)
//    }
//
//    func testOnChangeNotifications() {
//        // Setup monitor
//        let moc = stack.mainQueueContext
//        let authorMonitor = EntityMonitor<Author>(context: moc, frequency: .OnChange)
//        let authorMonitorDelegate = AuthorMonitorDelegate()
//        authorMonitor.setDelegate(authorMonitorDelegate)
//
//        // Test Insert
//        insertExpectation = expectation(withDescription: "EntityMonitor Insert Callback")
//        let _ = Author(managedObjectContext: moc)
//        waitForExpectations(withTimeout: 10, handler: nil)
//
//        // New Book (since we aren't observing this shouldn't show up in our delegate callback)
//        let _ = Book(managedObjectContext: moc)
//
//        // Test Update
//        updateExpectation = expectation(withDescription: "EntityMonitor Update Callback")
//        let existing = try! Author.findFirstInContext(moc)!
//        existing.firstName = "Robert"
//        moc.processPendingChanges()
//        waitForExpectations(withTimeout: 10, handler: nil)
//
//        // Test Delete
//        deleteExpectation = expectation(withDescription: "EntityMonitor Delete Callback")
//        let deleteMe = Author(managedObjectContext: moc)
//        stack.mainQueueContext.deleteObject(deleteMe)
//        waitForExpectations(withTimeout: 10, handler: nil)
//    }
//
//    func testFilterPredicate() {
//        // Create filter predicate
//        let matchingTitle = "nerd"
//        let predicate = Predicate(format: "title CONTAINS[cd] %@", matchingTitle)
//
//        // Setup monitor
//        let moc = stack.mainQueueContext
//        let filteredMonitor = EntityMonitor<Book>(context: moc, filterPredicate: predicate)
//        let bookMonitorDelegate = BookMonitorDelegate()
//        filteredMonitor.setDelegate(bookMonitorDelegate)
//
//        // Create an initial book
//        let newBook = Book(managedObjectContext: moc)
//        try! moc.saveContextAndWait()
//
//        // Look for an update
//        updateExpectation = expectation(withDescription: "EntityMonitor Update Callback")
//        newBook.title = "Swift Programming: The Big Nerd Ranch Guide"
//        try! moc.saveContextAndWait()
//        waitForExpectations(withTimeout: 10, handler: nil)
//
//        // Look for deletion
//        deleteExpectation = expectation(withDescription: "EntityMonitor Delete Callback")
//        moc.deleteObject(newBook)
//        try! moc.saveContextAndWait()
//        waitForExpectations(withTimeout: 10, handler: nil)
//    }
//}
