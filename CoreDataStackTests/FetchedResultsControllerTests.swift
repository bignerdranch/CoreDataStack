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
    var didChangeObjectCalls: [FetchedResultsObjectChange<Author>] = []
    var didChangeSectionCalls: [FetchedResultsSectionChange<Author>] = []
    var willChangeContentCount = 0
    var didChangeContentCount = 0
    var didPerformFetchCount = 0

    func fetchedResultsController(controller: FetchedResultsController<Author>,
        didChangeObject change: FetchedResultsObjectChange<Author>) {
            didChangeObjectCalls.append(change)
    }

    func fetchedResultsController(controller: FetchedResultsController<Author>,
        didChangeSection change: FetchedResultsSectionChange<Author>) {
            didChangeSectionCalls.append(change)
    }

    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<Author>) {
        ++willChangeContentCount
    }

    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<Author>) {
        ++didChangeContentCount
    }

    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<Author>) {
        ++didPerformFetchCount
    }
}

// MARK: - Test Cases

class FetchedResultsControllerTests: TempDirectoryTestCase {

    var coreDataStack: CoreDataStack!
    var fetchedResultsController: FetchedResultsController<Author>!
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

        // Setup fetched results controller
        let fr = NSFetchRequest(entityName: Author.entityName)
        fr.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        fetchedResultsController = FetchedResultsController<Author>(fetchRequest: fr, managedObjectContext: moc)
        fetchedResultsController.setDelegate(self.delegate)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testObjectInserts() {
        let moc = coreDataStack.mainQueueContext

        // Insert some authors
        for _ in 0..<10 {
            let _ = Author(managedObjectContext: moc)
        }
        try! moc.saveContextAndWait()

        XCTAssertEqual(delegate.didPerformFetchCount, 1)
        XCTAssertEqual(delegate.didChangeObjectCalls.count, 10)
    }
}
