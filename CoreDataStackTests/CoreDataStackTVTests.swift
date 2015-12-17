//
//  CoreDataStackTVTests.swift
//  CoreDataStackTVTests
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreDataStack

class CoreDataStackTVTests: XCTestCase {

    override func setUp() {
        super.setUp()

        do {
            let stack = try CoreDataStack.constructInMemoryStack(withModelName: "TestModel")
            XCTAssertNotNil(stack)
        } catch {
            XCTFail("\(error)")
        }
    }
}
