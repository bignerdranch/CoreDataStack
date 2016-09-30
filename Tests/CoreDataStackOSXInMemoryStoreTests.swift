//
//  CoreDataStackOSXInMemoryStoreTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/11/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackOSXInMemoryStoreTests: XCTestCase {

    var stack: CoreDataStack!

    func testInMemoryStackInitializationSucceeded() {
        do {
            stack = try CoreDataStack.constructInMemoryStack(modelName: "Sample",
                                                             in: unitTestBundle)
        } catch {
            failingOn(error)
        }

        XCTAssertNotNil(stack)
    }

}
