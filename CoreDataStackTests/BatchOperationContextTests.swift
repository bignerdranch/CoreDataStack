//
//  BatchOperationContextTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/21/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

class BatchOperationContextTests: TempDirectoryTestCase {

    var stack: CoreDataStack!
    var operationContext: NSManagedObjectContext!

    var bookFetchRequest: NSFetchRequest {
        get {
            return NSFetchRequest(entityName: "Book")
        }
    }

    override func setUp() {
        super.setUp()

        let ex1 = expectationWithDescription("StackSetup")
        let ex2 = expectationWithDescription("MocSetup")

        let bundle = NSBundle(forClass: CoreDataStackTests.self)

        do {
            try CoreDataStack.constructStack(withModelName: "TestModel", inBundle: bundle, inDirectoryAtURL: tempDirectory) { result in
                switch result {
                case .Success(let stack):
                    self.stack = stack
                    do {
                        try stack.newBatchOperationContext() { (result) in
                            switch result {
                            case .Success(let context):
                                self.operationContext = context
                            case .Failure(let error):
                                XCTFail("Error creating batch operation context: \(error)")
                            }
                            ex2.fulfill()
                        }
                    } catch let error {
                        XCTFail("Error creating batch operation context: \(error)")
                    }
                case .Failure(let error):
                    XCTFail("Error constructing stack: \(error)")
                }
                ex1.fulfill()
            }
        } catch let error {
            XCTFail("Error constructing stack: \(error)")
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testBatchOperation() {
        let operationMOC = self.operationContext
        operationMOC.performBlockAndWait() {
            for index in 1...10000 {
                if let newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: operationMOC) as? Book {
                    newBook.title = "New Book: \(index)"
                } else {
                    XCTFail("Failed to create a new Book object in the context")
                }
            }

            XCTAssertTrue(operationMOC.hasChanges)
            try! operationMOC.save()
        }

        let mainMOC = stack.mainQueueContext

        do {
            if let books = try mainMOC.executeFetchRequest(bookFetchRequest) as? [Book] {
                XCTAssertEqual(books.count, 10000)
            } else {
                XCTFail("Unable to fetch inserted books from main moc")
            }
        } catch {
            XCTFail("Unable to fetch inserted books from main moc")
        }
    }
}
