//
//  SaveTests.swift
//  CoreDataStack
//
//  Created by Brian Hardy on 8/27/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData
import XCTest

@testable import CoreDataStack

class SaveTests : TempDirectoryTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        createStack()
    }
    
    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }

    func testSaveContextToStore() {
        let privateQueueContext = coreDataStack.privateQueueContext
        let mainQueueContext = coreDataStack.mainQueueContext
        let worker = coreDataStack.newChildContext()
        let saveExpectation = expectationWithDescription("Async save callback")

        // Initial State Assertions
        worker.performBlockAndWait() {
            XCTAssertFalse(worker.hasChanges)
            XCTAssertEqual(try! Author.allInContext(worker).count, 0)
        }
        privateQueueContext.performBlockAndWait() {
            XCTAssertFalse(privateQueueContext.hasChanges)
            XCTAssertEqual(try! Author.allInContext(privateQueueContext).count, 0)
        }
        XCTAssertFalse(mainQueueContext.hasChanges)
        XCTAssertEqual(try! Author.allInContext(mainQueueContext).count, 0)

        // Insert Records
        worker.performBlockAndWait { () -> Void in
            for i in 1...5 {
                let author = Author(managedObjectContext: worker)
                author.firstName = "Jim \(i)"
                author.lastName = "Jones \(i)"
            }
        }

        // Perform Save
        worker.saveContextToStore() { result in
            switch result {
            case .Success:
                break
            case .Failure(let error):
                self.failingOn(error)
            }
            saveExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        // Final State Assertions
        worker.performBlockAndWait() {
            XCTAssertFalse(worker.hasChanges)
            XCTAssertEqual(try! Author.allInContext(worker).count, 5)
        }
        privateQueueContext.performBlockAndWait() {
            XCTAssertFalse(privateQueueContext.hasChanges)
            XCTAssertEqual(try! Author.allInContext(privateQueueContext).count, 5)
        }
        XCTAssertFalse(mainQueueContext.hasChanges)
        XCTAssertEqual(try! Author.allInContext(mainQueueContext).count, 5)
    }

    func testSaveContextToStoreAndWait() {
        let privateQueueContext = coreDataStack.privateQueueContext
        let mainQueueContext = coreDataStack.mainQueueContext
        let worker = coreDataStack.newChildContext()

        // Initial State Assertions
        worker.performBlockAndWait() {
            XCTAssertFalse(worker.hasChanges)
            XCTAssertEqual(try! Author.allInContext(worker).count, 0)
        }
        privateQueueContext.performBlockAndWait() {
            XCTAssertFalse(privateQueueContext.hasChanges)
            XCTAssertEqual(try! Author.allInContext(privateQueueContext).count, 0)
        }
        XCTAssertFalse(mainQueueContext.hasChanges)
        XCTAssertEqual(try! Author.allInContext(mainQueueContext).count, 0)

        // Insert Records
        worker.performBlockAndWait { () -> Void in
            for i in 1...5 {
                let author = Author(managedObjectContext: worker)
                author.firstName = "Jim \(i)"
                author.lastName = "Jones \(i)"
            }
        }

        // Perform Save
        do {
            try worker.saveContextToStoreAndWait()
        } catch {
            failingOn(error)
        }

        // Final State Assertions
        worker.performBlockAndWait() {
            XCTAssertFalse(worker.hasChanges)
            XCTAssertEqual(try! Author.allInContext(worker).count, 5)
        }
        privateQueueContext.performBlockAndWait() {
            XCTAssertFalse(privateQueueContext.hasChanges)
            XCTAssertEqual(try! Author.allInContext(privateQueueContext).count, 5)
        }
        XCTAssertFalse(mainQueueContext.hasChanges)
        XCTAssertEqual(try! Author.allInContext(mainQueueContext).count, 5)
    }

    func testBackgroundInsertAndSavePropagatesChanges() {
        // create a NSFRC looking for Authors
        let frc = authorsFetchedResultsController()
        let frcDelegate = EmptyFRCDelegate()
        frc.delegate = frcDelegate
        // fetch authors to ensure we got zero (and setup change notification)
        try! frc.performFetch()
        XCTAssertEqual(frc.fetchedObjects?.count, 0)
        // now insert some authors on a background MOC and save it
        let bgMoc = coreDataStack.newChildContext()
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: coreDataStack.privateQueueContext, handler: nil)
        bgMoc.performBlockAndWait { () -> Void in
            for i in 1...5 {
                let author = Author(managedObjectContext: bgMoc)
                author.firstName = "Jim \(i)"
                author.lastName = "Jones \(i)"
            }
            do {
                try bgMoc.saveContextAndWait()
            } catch let error {
                XCTFail("Could not save background context: \(error)")
            }
        }
        // assert we now have that many authors in the FRC
        XCTAssertEqual(frc.fetchedObjects?.count, 5)
        // wait for the persisting context to save async
        waitForExpectationsWithTimeout(5, handler: nil)
        // destroy and recreate the stack
        coreDataStack = nil
        createStack()
        // try the fetch again
        let newFRC = authorsFetchedResultsController()
        try! newFRC.performFetch()
        // assert that we still have the same number of authors
        XCTAssertEqual(newFRC.fetchedObjects?.count, 5)
    }
    
    private func authorsFetchedResultsController() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.mainQueueContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func testBackgroundSaveAsync() {
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: coreDataStack.mainQueueContext, handler: nil)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { () -> Void in
            let bgMoc = self.coreDataStack.newChildContext()
            bgMoc.performBlockAndWait { () -> Void in
                for i in 1...5 {
                    let author = Author(managedObjectContext: bgMoc)
                    author.firstName = "Jim \(i)"
                    author.lastName = "Jones \(i)"
                }
            }
            bgMoc.saveContext()
        }
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    private func createStack() {
        weak var setupExpectation = expectationWithDescription("stack setup")
        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: self.tempStoreURL) { (setupResult) -> Void in
            switch setupResult {
            case .Success(let stack):
                self.coreDataStack = stack
            default: break
            }
            setupExpectation?.fulfill()
        }
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

class EmptyFRCDelegate : NSObject, NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // nothing
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // nothing
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // nothing
    }
}
