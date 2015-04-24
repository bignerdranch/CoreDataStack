//
//  CoreDataStackTests.swift
//  CoreDataStackTests
//
//  Created by Robert Edwards on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import UIKit
import XCTest

import CoreDataStack

class CoreDataStackTests: XCTestCase {

    lazy var stack = {
        return NestedMOCStack(modelName: "TestModel", inBundle: NSBundle(forClass: CoreDataStackTests.self))
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialization() {
        let bundle = NSBundle(forClass: CoreDataStack.self)
        let model = bundle.URLForResource("TestModel", withExtension: "momd")
        XCTAssertNotNil(bundle)
        XCTAssertNotNil(model)
    }

}
