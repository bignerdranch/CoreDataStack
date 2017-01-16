//
//  ChildMOCCreationTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/22/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class ChildMOCCreationTests: TempDirectoryTestCase {

    var stack: CoreDataStack!

    override func setUp() {
        super.setUp()
        do {
            stack = try CoreDataStack.constructInMemoryStack(modelName: "Sample", in: unitTestBundle)
        } catch {
            XCTFail("Unexpected error in test: \(error)")
        }
    }

    func testBackgroundMOCCreation() {
        XCTAssertEqual(stack.newChildContext(type: .privateQueueConcurrencyType).concurrencyType, .privateQueueConcurrencyType)
    }

    func testMainQueueMOCCreation() {
        XCTAssertEqual(stack.newChildContext(type: .mainQueueConcurrencyType).concurrencyType, .mainQueueConcurrencyType)
    }

}
