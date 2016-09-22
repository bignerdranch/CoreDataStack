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
        willChangeContentCount += 1
    }

    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<Book>) {
        didChangeContentCount += 1
    }

    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<Book>) {
        didPerformFetchCount += 1
    }
}

// MARK: - Test Cases

class FetchedResultsControllerTests: XCTestCase {

    lazy var model: NSManagedObjectModel = {
        return self.unitTestBundle.managedObjectModel("Container_Example")
    }()
    lazy var container: NSPersistentContainer = {
        return NSPersistentContainer(name: "Container_Example", managedObjectModel: self.model)
    }()

    var fetchedResultsController: FetchedResultsController<Book>!
    var delegate = SampleFetchedResultsControllerDelegate()
    static let cacheName = "Cache"

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

        // Insert some Books
        let bookTitles = StubbedBookData.books
        for title in bookTitles {
            let book = Book(context: moc)
            book.title = title
        }
        try! moc.saveContextAndWait()

        // Setup fetched results controller
        let fr = NSFetchRequest()
        fr.entity = Book.entity()
        fr.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchedResultsController = FetchedResultsController<Book>(fetchRequest: fr, managedObjectContext: moc, sectionNameKeyPath: "firstInitial", cacheName: FetchedResultsControllerTests.cacheName)
        fetchedResultsController.setDelegate(self.delegate)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            failingOn(error)
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
        let moc = container.viewContext

        // Insert some Books
        let newBook = Book(context: moc)
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
        let moc = container.viewContext
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
        container.viewContext.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)

        // iOS 8 will report an .Update and .Move where as iOS 9 reports only the .Move
        XCTAssertLessThanOrEqual(delegate.didChangeObjectCalls.count, 2)

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
        case let .Update(object: book, indexPath: indexPath): // iOS 8 Reports and Update and Move
            XCTAssertEqual(book, lastBook)
            XCTAssertEqual(indexPath, expectedFromPath)
        case .Insert, .Delete:
            XCTFail("Incorrect change type: \(change)")
        }
    }

    func testObjectUpdates() {
        guard let firstBook = fetchedResultsController.fetchedObjects?.first else {
            XCTFail("first fetched book missing")
            return
        }
        let moc = container.viewContext

        // Update a book
        XCTAssertEqual(firstBook.authors?.count, 0)
        let author = Author(context: moc)
        author.firstName = "George"
        author.lastName = "Orwell"
        firstBook.addAuthor(author)

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
            XCTAssertEqual(book.authors?.count, 1)
            guard let authors = book.authors?.allObjects as? [Author] else {
                XCTFail("Missing authors")
                return
            }
            XCTAssertEqual(authors.first, author)
            XCTAssertEqual(indexPath, NSIndexPath(forRow: 0, inSection: 0))
        case .Delete, .Move, .Insert:
            XCTFail("Wrong type of update")
        }
    }

    func testSectionInserts() {
        let moc = container.viewContext

        //Create a new book with a title that will create a new section
        let newBook = Book(context: moc)
        newBook.title = "##@%@#%^"
        moc.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
        XCTAssertEqual(delegate.didChangeSectionCalls.count, 1)
        guard let sectionChange = delegate.didChangeSectionCalls.first else {
            XCTFail("Missing section change assertion")
            return
        }

        switch sectionChange {
        case let .Insert(sectionInfo, sectionIndex):
            XCTAssertEqual(sectionInfo.indexTitle, "#")
            XCTAssertEqual(sectionInfo.objects.first, newBook)
            XCTAssertEqual(sectionInfo.objects.count, 1)
            XCTAssertEqual(sectionInfo.name, "#")
            XCTAssertEqual(sectionIndex, 0)
        case .Delete:
            XCTFail("Wrong section update type")
        }
    }

    func testSectionDeletions() {
        let moc = container.viewContext

        // Delete a book that will remove an entire section
        guard let firstBook = fetchedResultsController.first else {
            XCTFail("Missing first book")
            return
        }
        XCTAssertEqual(firstBook.title, "1984")
        moc.deleteObject(firstBook)
        moc.processPendingChanges()

        XCTAssertEqual(delegate.didChangeContentCount, 1)
        XCTAssertEqual(delegate.willChangeContentCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
        XCTAssertEqual(delegate.didChangeSectionCalls.count, 1)
        guard let sectionChange = delegate.didChangeSectionCalls.first else {
            XCTFail("Missing the section delete change")
            return
        }
        switch sectionChange {
        case let .Delete(sectionInfo, sectionIndex):
            XCTAssertEqual(sectionInfo.objects.count, 0)
            XCTAssertEqual(sectionInfo.name, "1")
            XCTAssertEqual(sectionInfo.indexTitle, "1")
            XCTAssertEqual(sectionIndex, 0)
        case .Insert:
            XCTFail("Incorrect section update type")
        }
    }

    func testCacheName() {
        XCTAssertEqual(fetchedResultsController.cacheName, FetchedResultsControllerTests.cacheName)
    }
}
