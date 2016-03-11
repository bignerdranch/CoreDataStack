//
//  CoreDataStackOSXInMemoryStoreTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/11/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackOSXInMemoryStoreTests: XCTestCase {

    var stack: CoreDataStack!

    func testInMemoryStackInitializationSucceeded() {
        do {
            stack = try CoreDataStack.constructInMemoryStack(withModelName: "Sample", inBundle: unitTestBundle)
        } catch {
            failingOn(error)
        }

        XCTAssertNotNil(stack)
    }

}
