//
//  BatchOperationContextTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/21/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

// swiftlint:disable force_try

import XCTest

import CoreData

@testable import CoreDataStack

class BatchOperationContextTests: TempDirectoryTestCase {

    var sqlStack: CoreDataStack!
    var operationContext: NSManagedObjectContext!

    var bookFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
    }

    override func setUp() {
        super.setUp()

        weak var ex1 = expectation(description: "StackSetup")
        weak var ex2 = expectation(description: "MocSetup")

        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: tempStoreURL) { result in
            switch result {
            case .success(let stack):
                self.sqlStack = stack
                stack.newBatchOperationContext() { (result) in
                    switch result {
                    case .success(let context):
                        self.operationContext = context
                    case .failure(let error):
                        XCTFail("Error creating batch operation context: \(error)")
                    }
                    ex2?.fulfill()
                }
            case .failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            ex1?.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testBatchOperation() {
        let operationMOC = self.operationContext
        operationMOC?.performAndWait() {
            for index in 1...10000 {
                if let newBook = NSEntityDescription.insertNewObject(forEntityName: "Book", into: operationMOC!) as? Book {
                    newBook.title = "New Book: \(index)"
                } else {
                    XCTFail("Failed to create a new Book object in the context")
                }
            }

            XCTAssertTrue((operationMOC?.hasChanges)!)
            try! operationMOC?.save()
        }

        let mainMOC = sqlStack.mainQueueContext

        do {
            if let books = try mainMOC.fetch(bookFetchRequest) as? [Book] {
                XCTAssertEqual(books.count, 10000)
            } else {
                XCTFail("Unable to fetch inserted books from main moc")
            }
        } catch {
            XCTFail("Unable to fetch inserted books from main moc")
        }
    }
}
