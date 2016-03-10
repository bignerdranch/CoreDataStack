//
//  CoreDataStackOSXTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/1/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackOSXTests: XCTestCase {

    var memoryStack: CoreDataStack!
    var sqlLiteStack: CoreDataStack!

    lazy var testBundle: NSBundle = {
        return NSBundle(forClass: self.dynamicType)
    }()
    lazy var sqlLiteStoreDirectory: NSURL = {
        let fm = NSFileManager.defaultManager()
        let urls = fm.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        guard let identifier = self.testBundle.bundleIdentifier,
            let storeURL = urls.first?.URLByAppendingPathComponent(identifier, isDirectory: true) else {
                fatalError("Failed to create store directory URL")
        }
        return storeURL
    }()
    var storeURL: NSURL {
        return self.sqlLiteStoreDirectory.URLByAppendingPathComponent("Sample").URLByAppendingPathExtension("sqlite")
    }

    override func setUp() {
        super.setUp()

        do {
            memoryStack = try CoreDataStack.constructInMemoryStack(withModelName: "Sample", inBundle: testBundle)
        } catch {
            XCTFail("Unepected error in test: \(error)")
        }

        let setupExpectation = expectationWithDescription("Setup")
        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: testBundle, withStoreURL: storeURL) { result in
            switch result {
            case .Success(let stack):
                self.sqlLiteStack = stack
            case .Failure(let error):
                XCTFail("Failed to setup sqlite stack with error: \(error)")
            }
            setupExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    override func tearDown() {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(sqlLiteStoreDirectory)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testInMemoryInitialization() {
        XCTAssertNotNil(memoryStack)
    }

    func testSQLiteInitialization() {
        XCTAssertNotNil(sqlLiteStack)
        guard let expectedPath = storeURL.path else {
            XCTFail("Expected path is not a valid RFC1808 file path")
            return
        }
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(expectedPath))
    }
}
