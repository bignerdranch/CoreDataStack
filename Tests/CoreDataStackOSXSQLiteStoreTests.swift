//
//  CoreDataStackOSXSQLiteStoreTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/1/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackOSXTests: XCTestCase {

    var stack: CoreDataStack!

    lazy var sqlLiteStoreDirectory: NSURL = {
        let fm = NSFileManager.defaultManager()
        let urls = fm.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        guard let identifier = self.unitTestBundle.bundleIdentifier,
            let storeURL = urls.first?.URLByAppendingPathComponent(identifier, isDirectory: true) else {
                fatalError("Failed to create store directory URL")
        }
        return storeURL
    }()
    var storeURL: NSURL? {
        return self.sqlLiteStoreDirectory.URLByAppendingPathComponent("Sample")?.URLByAppendingPathExtension("sqlite")
    }

    override func tearDown() {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(sqlLiteStoreDirectory)
        } catch {
            failingOn(error)
        }
    }

    func testSQLiteStackInitializationCreatedStackAndStoreFile() {
        let setupExpectation = expectationWithDescription("Setup")
        guard let storeURL = storeURL else {
            XCTFail("Failed to create store URL")
            return
        }

        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: storeURL) { result in
            switch result {
            case .success(let stack):
                self.stack = stack
            case .failure(let error):
                XCTFail("Failed to setup sqlite stack with error: \(error)")
            }
            setupExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNotNil(stack)
        guard let expectedPath = storeURL.path else {
            XCTFail("Expected path is not a valid RFC1808 file path")
            return
        }
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(expectedPath))
    }
}
