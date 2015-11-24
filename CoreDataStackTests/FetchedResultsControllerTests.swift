//
//  FetchedResultsControllerTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/19/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData
import CoreDataStack

// MARK: - FetchedResultsControllerDelegate

class SampleFetchedResultsControllerDelegate: FetchedResultsControllerDelegate {
    var didChangeObjectCalls: [FetchedResultsObjectChange<Book>] = []
    var didChangeSectionCalls: [FetchedResultsSectionChange<Book>] = []
    var willChangeContentCount = 0
    var didChangeContentCount = 0
    var didPerformFetchCount = 0

    func fetchedResultsController(controller: FetchedResultsController<Book>,
        didChangeObject change: FetchedResultsObjectChange<Book>) {
            didChangeObjectCalls.append(change)
    }

    func fetchedResultsController(controller: FetchedResultsController<Book>,
        didChangeSection change: FetchedResultsSectionChange<Book>) {
            didChangeSectionCalls.append(change)
    }

    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<Book>) {
        ++willChangeContentCount
    }

    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<Book>) {
        ++didChangeContentCount
    }

    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<Book>) {
        ++didPerformFetchCount
    }
}

// MARK: - Test Cases

class FetchedResultsControllerTests: TempDirectoryTestCase {

    var coreDataStack: CoreDataStack!
    var fetchedResultsController: FetchedResultsController<Book>!
    var delegate = SampleFetchedResultsControllerDelegate()

    override func setUp() {
        super.setUp()

        let setupEx = expectationWithDescription("Setup")
        let bundle = NSBundle(forClass: CoreDataStackTests.self)

        // Setup Stack
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.coreDataStack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            setupEx.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        let moc = coreDataStack.mainQueueContext

        // Insert some Books
        let bookTitles = StubbedBookData.books
        for title in bookTitles {
            let book = Book(managedObjectContext: moc)
            book.title = title
        }
        try! moc.saveContextAndWait()

        // Setup fetched results controller
        let fr = NSFetchRequest(entityName: Book.entityName)
        fr.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchedResultsController = FetchedResultsController<Book>(fetchRequest: fr, managedObjectContext: moc, sectionNameKeyPath: "firstInitial")
        fetchedResultsController.setDelegate(self.delegate)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testInitialFetch() {
        guard let books = fetchedResultsController.fetchedObjects else {
            XCTFail("Books missing from fetch")
            return
        }
        XCTAssertEqual(books.count, 100)

        guard let sections = fetchedResultsController.sections else {
            XCTFail("Sections missing")
            return
        }
        XCTAssertEqual(sections.count, 19)

        let topSection = sections[0]
        XCTAssertEqual(topSection.objects.count, 1)

        guard let topBook = topSection.objects.first else {
            XCTFail("Top book missing from first section")
            return
        }
        XCTAssertEqual(topBook.title, "1984")

        let aSection = sections[1]
        XCTAssertEqual(aSection.name, "A")
        XCTAssertEqual(aSection.indexTitle, "A")
    }

    func testObjectInserts() {
        let moc = coreDataStack.mainQueueContext

        // Insert some Books
        let newBook = Book(managedObjectContext: moc)
        newBook.title = "1111"
        moc.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)

        guard let change = delegate.didChangeObjectCalls.first else {
            XCTFail("Missing object change")
            return
        }
        switch change {
        case let .Insert(book, indexPath):
            XCTAssertEqual(book, newBook)
            XCTAssertEqual(indexPath, NSIndexPath(forRow: 0, inSection: 0))
            break
        case .Move, .Delete, .Update:
            XCTFail("Incorrect update type")
        }
    }

    func testObjectDeletions() {
        guard let firstBook = fetchedResultsController.fetchedObjects?.first else {
            XCTFail("first fetched book missing")
            return
        }

        // Delete a book
        let moc = coreDataStack.mainQueueContext
        moc.deleteObject(firstBook)
        moc.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
        guard let change = delegate.didChangeObjectCalls.first else {
            XCTFail("Missing object change object")
            return
        }

        switch change {
        case .Delete(let book, let indexPath):
            XCTAssertEqual(book, firstBook)
            XCTAssertEqual(indexPath, NSIndexPath(forRow: 0, inSection: 0))
        case .Update, .Move, .Insert:
            XCTFail("Unexpected change type")
        }
    }

    func testObjectMoves() {
        guard let lastBook = fetchedResultsController.fetchedObjects?.last else {
            XCTFail("Last book missing")
            return
        }

        XCTAssertEqual(lastBook.title, "Wide Sargasso Sea")

        // Remame the book
        lastBook.title = "Narrow Sargasso Sea"
        coreDataStack.mainQueueContext.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
        guard let change = delegate.didChangeObjectCalls.first else {
            XCTFail("Missing change object")
            return
        }

        let expectedToPath = NSIndexPath(forRow: 1, inSection: 11)
        let expectedFromPath = NSIndexPath(forRow: 3, inSection: 18)

        switch change {
        case let .Move(object: book, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath):
            XCTAssertEqual(book, lastBook)
            XCTAssertEqual(fromIndexPath, expectedFromPath)
            XCTAssertEqual(toIndexPath, expectedToPath)
            return
        case .Update, .Insert, .Delete:
            XCTFail("Incorrect change type")
        }
    }

    func testObjectUpdates() {
        guard let firstBook = fetchedResultsController.fetchedObjects?.first else {
            XCTFail("first fetched book missing")
            return
        }
        let moc = coreDataStack.mainQueueContext

        // Update a book
        XCTAssertEqual(firstBook.authors.count, 0)
        let author = Author(managedObjectContext: moc)
        author.firstName = "George"
        author.lastName = "Orwell"
        firstBook.authors.insert(author)
        moc.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
        guard let change = delegate.didChangeObjectCalls.first else {
            XCTFail("Update missing")
            return
        }

        switch change {
        case let .Update(book, indexPath):
            XCTAssertEqual(book, firstBook)
            XCTAssertEqual(book.authors.count, 1)
            XCTAssertEqual(book.authors.first, author)
            XCTAssertEqual(indexPath, NSIndexPath(forRow: 0, inSection: 0))
        case .Delete, .Move, .Insert:
            XCTFail("Wrong type of update")
        }
    }

    func testSectionInserts() {
        XCTFail("Not implemented")
        //delegate.didChangeSectionCalls
    }

    func testSectionDeletions() {
        XCTFail("Not implemented")
        //delegate.didChangeSectionCalls
    }
}
