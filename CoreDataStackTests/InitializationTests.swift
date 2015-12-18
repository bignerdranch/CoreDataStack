//
//  NestedContextStackTests.swift
//  NestedContextStackTests
//
//  Created by Robert Edwards on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

@testable import CoreDataStack

class CoreDataStackTests: TempDirectoryTestCase {

    var stack: CoreDataStack!
    var memoryStore: CoreDataStack!

    func testInitialization() {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")

        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }

        do {
            try memoryStore = CoreDataStack.constructInMemoryStack(withModelName: "TestModel", inBundle: bundle)
        } catch {
            XCTFail("\(error)")
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)

        XCTAssertNotNil(memoryStore.mainQueueContext)
        XCTAssertNotNil(memoryStore.privateQueueContext)
    }

    func testInitializationToDefaultDirectory() {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")
        
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)
        XCTAssertTrue(fileExists("TestModel.sqlite", directory: .DocumentDirectory))
    }
 
    func testInitializationToAlternateDirectory() {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")
        
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, inDirectory: .CachesDirectory) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)
        XCTAssertTrue(fileExists("TestModel.sqlite", directory: .CachesDirectory))
    }
    
    func testInitializationWithStoreURLOverrideInDirectory() {
        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let ex1 = expectationWithDescription("SQLite Callback")
        removeIfExists("TestModel.sqlite", directory: .CachesDirectory)
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL, inDirectory: .CachesDirectory) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            ex1.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNotNil(stack.mainQueueContext)
        XCTAssertNotNil(stack.privateQueueContext)
        XCTAssertFalse(fileExists("TestModel.sqlite", directory: .CachesDirectory))
    }
    
    private func fileExists(fileName:String,directory:NSSearchPathDirectory) -> Bool {
        let urls = NSFileManager.defaultManager().URLsForDirectory(directory, inDomains: .UserDomainMask)
        let fileURL = urls.first?.URLByAppendingPathComponent(fileName)
        if let filePath = fileURL?.path {
            return NSFileManager.defaultManager().fileExistsAtPath(filePath)
        }
        else {
            return false
        }
    }
    
    private func removeIfExists(fileName:String,directory:NSSearchPathDirectory) {
        let urls = NSFileManager.defaultManager().URLsForDirectory(directory, inDomains: .UserDomainMask)
        let fileURL = urls.first?.URLByAppendingPathComponent(fileName)
        if let filePath = fileURL?.path {
            if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                }
                catch {
                }
            }
        }
    }
}
