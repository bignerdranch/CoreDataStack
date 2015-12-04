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
        do {
            let _ = Book(managedObjectContext: stack.mainQueueContext)
            try stack.mainQueueContext.saveContextAndWait()

            guard let firstBook = try Book.findFirstInContext(stack.mainQueueContext) else {
                XCTFail("First Book not found"); return
            }
            firstBook.title = "Testing"
            try! stack.mainQueueContext.saveContextAndWait()

            let predicate1 = NSPredicate(format: "title CONTAINS[cd] %@", "Bob")
            let notFound = try Book.findFirstInContext(stack.mainQueueContext, predicate: predicate1)
            XCTAssertNil(notFound)

            let predicate2 = NSPredicate(format: "title CONTAINS[cd] %@", "Test")
            guard let _ = try Book.findFirstInContext(stack.mainQueueContext, predicate: predicate2) else {
                XCTFail("Failed to find first with matching title."); return
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testAllInContext() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(managedObjectContext: stack.mainQueueContext)
            try! stack.mainQueueContext.saveContextAndWait()
        }

        do {
            let allBooks = try Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, totalBooks)
        } catch {
            XCTFail("\(error)")
        }
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

        do {
            var allBooks = try Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, totalBooks)

            try Book.removeAllExcept(exceptionBooks, inContext: stack.mainQueueContext)
            allBooks = try Book.allInContext(stack.mainQueueContext)
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

        do {
            var allBooks = try Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, totalBooks)

            try Book.removeAllInContext(stack.mainQueueContext)
            allBooks = try Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, 0)
        } catch {
            XCTFail("\(error)")
        }
    }
}
