//
//  CoreDataModelableTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData
import CoreDataStack

class CoreDataModelableTests: TempDirectoryTestCase {
    var stack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let expectation = expectationWithDescription("callback")
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNewObject() {
        let book = Book(managedObjectContext: stack.mainQueueContext)
        XCTAssertNotNil(book)
    }

    func testFindFirst() {
        let _ = Book(managedObjectContext: stack.mainQueueContext)
        try! stack.mainQueueContext.saveContextAndWait()

        let firstBook = Book.findFirst(nil, context: stack.mainQueueContext)
        XCTAssertNotNil(firstBook)

        firstBook?.title = "Testing"
        try! stack.mainQueueContext.saveContextAndWait()

        let predicate1 = NSPredicate(format: "title CONTAINS[cd] %@", "Bob")
        let notFound = Book.findFirst(predicate1, context: stack.mainQueueContext)
        XCTAssertNil(notFound)

        let predicate2 = NSPredicate(format: "title CONTAINS[cd] %@", "Test")
        let found = Book.findFirst(predicate2, context: stack.mainQueueContext)
        XCTAssertNotNil(found)
    }

    func testAllInContext() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(managedObjectContext: stack.mainQueueContext)
            try! stack.mainQueueContext.saveContextAndWait()
        }

        let allBooks = Book.allInContext(stack.mainQueueContext)
        XCTAssertEqual(allBooks.count, totalBooks)
    }

    func testRemoveAllExcept() {
        let totalBooks = 5
        var exceptionBooks = [Book]()
        for counter in 0..<totalBooks {
            let newBook = Book(managedObjectContext: stack.mainQueueContext)
            try! stack.mainQueueContext.saveContextAndWait()

            if (counter % 2 == 0) {
                exceptionBooks.append(newBook)
            }
        }

        var allBooks = Book.allInContext(stack.mainQueueContext)
        XCTAssertEqual(allBooks.count, totalBooks)

        do {
            try Book.removeAllExcept(exceptionBooks, inContext: stack.mainQueueContext)
            allBooks = Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, exceptionBooks.count)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRemoveAll() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(managedObjectContext: stack.mainQueueContext)
            try! stack.mainQueueContext.saveContextAndWait()
        }

        var allBooks = Book.allInContext(stack.mainQueueContext)
        XCTAssertEqual(allBooks.count, totalBooks)

        do {
            try Book.removeAll(stack.mainQueueContext)
            allBooks = Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, 0)
        } catch {
            XCTFail("\(error)")
        }
    }
}
