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

    func testObjectInserts() {
        let moc = coreDataStack.mainQueueContext

        // Insert some Books
        let bookTitles = StubbedBookData.books
        for title in bookTitles {
            let book = Book(managedObjectContext: moc)
            book.title = title
        }
        try! moc.saveContextAndWait()

        XCTAssertEqual(delegate.didPerformFetchCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 100)
    }
}
