//
//  NSError+CoreDataValidationErrors.swift
//  CoreDataSMS
//
//  Created by Robert Edwards on 4/3/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

extension NSError {
    func errorByCombiningError(secondError: NSError) -> NSError {
        var userInfo: [NSObject:AnyObject]!
        var errors = [secondError]
        if let userInfo = userInfo where code == NSValidationMultipleErrorsError, let originalErrors = userInfo[NSDetailedErrorsKey] as? [NSError] {
            errors += originalErrors
        } else {
            errors.append(self)
        }
        userInfo ?? [NSObject: AnyObject]()
        userInfo[NSDetailedErrorsKey] = errors

        return NSError(domain: NSCocoaErrorDomain, code: NSValidationMultipleErrorsError, userInfo: userInfo)
    }
}
