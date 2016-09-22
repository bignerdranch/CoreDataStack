//
//  NSManagedObjectExtensionTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class NSManagedObjectExtensionTests: XCTestCase {

    lazy var model: NSManagedObjectModel = {
        return self.unitTestBundle.managedObjectModel("Container_Example")
    }()
    lazy var container: NSPersistentContainer = {
        return NSPersistentContainer(name: "Container_Example", managedObjectModel: self.model)
    }()

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        weak var expectation = self.expectationWithDescription("callback")

        let configuration = NSPersistentStoreDescription()
        configuration.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [configuration]

        container.loadPersistentStoresWithCompletionHandler() { storeDescription, error in
            if let error = error {
                XCTFail("Unresolved error \(error), \(error.userInfo)")
            }
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testNewObject() {
        let book = Book(context: container.viewContext)
        XCTAssertNotNil(book)
    }

    func testFindFirst() {
        do {
            let _ = Book(context: container.viewContext)
            try container.viewContext.saveContextAndWait()

            guard let firstBook = try Book.findFirstInContext(container.viewContext) else {
                XCTFail("First Book not found"); return
            }
            firstBook.title = "Testing"
            try! container.viewContext.saveContextAndWait()

            let predicate1 = NSPredicate(format: "title CONTAINS[cd] %@", "Bob")
            let notFound = try Book.findFirstInContext(container.viewContext, predicate: predicate1)
            XCTAssertNil(notFound)

            let predicate2 = NSPredicate(format: "title CONTAINS[cd] %@", "Test")
            guard let _ = try Book.findFirstInContext(container.viewContext, predicate: predicate2) else {
                XCTFail("Failed to find first with matching title."); return
            }
        } catch {
            failingOn(error)
        }
    }

    func testAllInContext() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(context: container.viewContext)
            try! container.viewContext.saveContextAndWait()
        }

        do {
            let allBooks = try Book.allInContext(container.viewContext)
            XCTAssertEqual(allBooks.count, totalBooks)
        } catch {
            failingOn(error)
        }
    }

    func testAllInContextWithPredicateAndSortDescriptor() {
        let iOSBook = Book(context: container.viewContext)
        iOSBook.title = "iOS Programming: The Big Nerd Ranch Guide"

        let swiftBook = Book(context: container.viewContext)
        swiftBook.title = "Swift Programming: The Big Nerd Ranch Guide"

        let warAndPeace = Book(context: container.viewContext)
        warAndPeace.title = "War and Peace"

        do {
            try container.viewContext.save()
        } catch {
            XCTFail("Failed to save with error: \(error)")
        }

        let sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", "Big Nerd Ranch")

        do {
            let matchingBooks = try Book.allInContext(container.viewContext, predicate: predicate, sortDescriptors: sortDescriptors)
            XCTAssertEqual(matchingBooks.count, 2)
            XCTAssertEqual(matchingBooks.first, swiftBook)
            XCTAssertEqual(matchingBooks.last, iOSBook)
        } catch {
            XCTFail("Failed to fetch with error: \(error)")
        }
    }

    func testCountInContext() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(context: container.viewContext)
            try! container.viewContext.saveContextAndWait()
        }

        do {
            let booksCount = try Book.countInContext(container.viewContext)
            XCTAssertEqual(booksCount, totalBooks)
        } catch {
            failingOn(error)
        }
    }

    func testCountInContextWithPredicate() {
        let iOSBook = Book(context: container.viewContext)
        iOSBook.title = "iOS Programming: The Big Nerd Ranch Guide"

        let swiftBook = Book(context: container.viewContext)
        swiftBook.title = "Swift Programming: The Big Nerd Ranch Guide"

        let warAndPeace = Book(context: container.viewContext)
        warAndPeace.title = "War and Peace"

        do {
            try container.viewContext.save()
        } catch {
            XCTFail("Failed to save with error: \(error)")
        }

        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", "Big Nerd Ranch")

        do {
            let matchingBooksCount = try Book.countInContext(container.viewContext, predicate: predicate)
            XCTAssertEqual(matchingBooksCount, 2)
        } catch {
            XCTFail("Failed to fetch with error: \(error)")
        }
    }

    func testRemoveAllExcept() {
        let totalBooks = 5
        var exceptionBooks = [Book]()
        for counter in 0..<totalBooks {
            let newBook = Book(context: container.viewContext)
            try! container.viewContext.saveContextAndWait()

            if (counter % 2 == 0) {
                exceptionBooks.append(newBook)
            }
        }

        do {
            var allBooks = try Book.allInContext(container.viewContext)
            XCTAssertEqual(allBooks.count, totalBooks)

            try Book.removeAllInContext(container.viewContext, except: exceptionBooks)
            allBooks = try Book.allInContext(container.viewContext)
            XCTAssertEqual(allBooks.count, exceptionBooks.count)
        } catch {
            failingOn(error)
        }
    }

    func testRemoveAll() {
        let totalBooks = 5
        for _ in 0..<totalBooks {
            let _ = Book(context: container.viewContext)
            try! container.viewContext.saveContextAndWait()
        }

        do {
            var allBooks = try Book.allInContext(container.viewContext)
            XCTAssertEqual(allBooks.count, totalBooks)

            try Book.removeAllInContext(container.viewContext)
            allBooks = try Book.allInContext(container.viewContext)
            XCTAssertEqual(allBooks.count, 0)
        } catch {
            failingOn(error)
        }
    }
}
