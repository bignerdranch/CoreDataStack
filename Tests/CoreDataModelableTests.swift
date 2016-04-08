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

        weak var expectation = expectationWithDescription("callback")
        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            expectation?.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNewObject() {
        let book = Book(managedObjectContext: stack.mainQueueContext)
        XCTAssertNotNil(book)
    }
    
    func testCreateNewObject() {
        let title = "Swift Programming: The Big Nerd Ranch Guide"
        let book = Book.createInContext(stack.mainQueueContext) {
            $0.title = title
        }
        XCTAssertEqual(book.title, title)
    }
    
    func testUpdateObject() {
        let iOSBook = Book(managedObjectContext: stack.mainQueueContext)
        iOSBook.title = "iOS Programming: The Big Nerd Ranch Guide"
        
        let swiftBook = Book(managedObjectContext: stack.mainQueueContext)
        swiftBook.title = "Swift Programming: The Big Nerd Ranch Guide"
        
        let warAndPeace = Book(managedObjectContext: stack.mainQueueContext)
        warAndPeace.title = "War and Peace"
        
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", "The Big Nerd Ranch Guide")
        
        do {
            let updatedBooks = try Book.updateInContext(stack.mainQueueContext, predicate: predicate) {
                $0.title = ($0.title ?? "") + " - UPDATED"
            }
            
            XCTAssertEqual(updatedBooks.count, 2)
            
            let updatedBooksTitles = updatedBooks.flatMap({ $0.title })
            let updatedBooksTitlesExpectation = [
                "iOS Programming: The Big Nerd Ranch Guide - UPDATED",
                "Swift Programming: The Big Nerd Ranch Guide - UPDATED"
            ]
            XCTAssertEqual(updatedBooksTitles.sort(), updatedBooksTitlesExpectation.sort())
        } catch {
            failingOn(error)
        }
    }
    
    func testUpdateOrCreateNewObjectShouldCreate() {
        do {
            let createdBooks = try Book.updateOrCreateInContext(stack.mainQueueContext, predicate: nil) {
                $0.title = "iOS Programming: The Big Nerd Ranch Guide"
            }
            
            XCTAssertEqual(createdBooks.count, 1)
            XCTAssertEqual(createdBooks.first?.title, "iOS Programming: The Big Nerd Ranch Guide")
        } catch {
            failingOn(error)
        }
    }
    
    func testUpdateOrCreateNewObjectShouldUpdate() {
        let iOSBook = Book(managedObjectContext: stack.mainQueueContext)
        iOSBook.title = "iOS Programming: The Big Nerd Ranch Guide"
        
        let swiftBook = Book(managedObjectContext: stack.mainQueueContext)
        swiftBook.title = "Swift Programming: The Big Nerd Ranch Guide"
        
        let warAndPeace = Book(managedObjectContext: stack.mainQueueContext)
        warAndPeace.title = "War and Peace"
        
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", "The Big Nerd Ranch Guide")
        
        do {
            let updatedBooks = try Book.updateOrCreateInContext(stack.mainQueueContext, predicate: predicate) {
                $0.title = ($0.title ?? "") + " - UPDATED"
            }
            
            XCTAssertEqual(updatedBooks.count, 2)
            
            let updatedBooksTitles = updatedBooks.flatMap({ $0.title })
            let updatedBooksTitlesExpectation = [
                "iOS Programming: The Big Nerd Ranch Guide - UPDATED",
                "Swift Programming: The Big Nerd Ranch Guide - UPDATED"
            ]
            XCTAssertEqual(updatedBooksTitles.sort(), updatedBooksTitlesExpectation.sort())
        } catch {
            failingOn(error)
        }
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
            failingOn(error)
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
            failingOn(error)
        }
    }

    func testAllInContextWithPredicateAndSortDescriptor() {
        let iOSBook = Book(managedObjectContext: stack.mainQueueContext)
        iOSBook.title = "iOS Programming: The Big Nerd Ranch Guide"

        let swiftBook = Book(managedObjectContext: stack.mainQueueContext)
        swiftBook.title = "Swift Programming: The Big Nerd Ranch Guide"

        let warAndPeace = Book(managedObjectContext: stack.mainQueueContext)
        warAndPeace.title = "War and Peace"

        do {
            try stack.mainQueueContext.save()
        } catch {
            XCTFail("Failed to save with error: \(error)")
        }

        let sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", "Big Nerd Ranch")

        do {
            let matchingBooks = try Book.allInContext(stack.mainQueueContext, predicate: predicate, sortDescriptors: sortDescriptors)
            XCTAssertEqual(matchingBooks.count, 2)
            XCTAssertEqual(matchingBooks.first, swiftBook)
            XCTAssertEqual(matchingBooks.last, iOSBook)
        } catch {
            XCTFail("Failed to fetch with error: \(error)")
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

            try Book.removeAllInContext(stack.mainQueueContext, except: exceptionBooks)
            allBooks = try Book.allInContext(stack.mainQueueContext)
            XCTAssertEqual(allBooks.count, exceptionBooks.count)
        } catch {
            failingOn(error)
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
            failingOn(error)
        }
    }
}
