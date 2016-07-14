//
//  TempDirectoryTestCase.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

class TempDirectoryTestCase: XCTestCase {

    lazy var tempStoreURL: NSURL? = {
        return self.tempStoreDirectory?.URLByAppendingPathComponent("testmodel.sqlite")
    }()

    private lazy var tempStoreDirectory: NSURL? = {
        let baseURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
        guard let tempDir = baseURL.URLByAppendingPathComponent("XXXXXX") else {
            assertionFailure("Unable to create temp directory URL")
            return nil
        }
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDir,
                withIntermediateDirectories: true,
                attributes: nil)
            return tempDir
        } catch {
            assertionFailure("\(error)")
        }
        return nil
    }()

    private func removeTempDir() {
        if let tempStoreDirectory = tempStoreDirectory {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tempStoreDirectory)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }
    
    override func tearDown() {
        removeTempDir()
        super.tearDown()
    }
}
