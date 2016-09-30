//
//  CoreDataStackOSXSQLiteStoreTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/1/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

@testable import CoreDataStack

class CoreDataStackOSXTests: XCTestCase {

    var stack: CoreDataStack!

    lazy var sqlLiteStoreDirectory: URL = {
        let fm = FileManager.default
        let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let identifier = self.unitTestBundle.bundleIdentifier,
            let storeURL = urls.first?.appendingPathComponent(identifier, isDirectory: true) else {
                fatalError("Failed to create store directory URL")
        }
        return storeURL
    }()
    var storeURL: URL {
        return self.sqlLiteStoreDirectory.appendingPathComponent("Sample").appendingPathExtension("sqlite")
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(at: sqlLiteStoreDirectory)
        } catch {
            failingOn(error)
        }
    }

    func testSQLiteStackInitializationCreatedStackAndStoreFile() {
        let setupExpectation = expectation(description: "Setup")
        CoreDataStack.constructSQLiteStack(modelName: "Sample", in: unitTestBundle, at: storeURL as URL) { result in
            switch result {
            case .success(let stack):
                self.stack = stack
            case .failure(let error):
                XCTFail("Failed to setup sqlite stack with error: \(error)")
            }
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNotNil(stack)

        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
    }
}
