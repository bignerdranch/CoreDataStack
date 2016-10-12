//
//  TempDirectoryTestCase.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 12/17/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import XCTest

class TempDirectoryTestCase: XCTestCase {

    lazy var tempStoreURL: URL? = {
        return self.tempStoreDirectory?.appendingPathComponent("testmodel.sqlite")
    }()

    private lazy var tempStoreDirectory: URL? = {
        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempDir = baseURL.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir,
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
                try FileManager.default.removeItem(at: tempStoreDirectory)
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
