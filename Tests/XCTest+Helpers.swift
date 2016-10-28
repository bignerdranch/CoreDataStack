//
//  XCTest+Helpers.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 3/11/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import Foundation
import XCTest

extension XCTest {
    var unitTestBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    func failingOn(_ error: Error) {
        XCTFail("Failing with error: \(error) in: \(self)")
    }
}
