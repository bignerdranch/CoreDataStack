//
//  Bundle+CoreDataModelHelper.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

extension Bundle {
    static private let modelExtension = "momd"
    /**
     Attempts to return an instance of NSManagedObjectModel for a given name within the bundle.

     - parameter name: The file name of the model without the extension.
     - returns: The NSManagedObjectModel from the bundle with the given name.
     **/
    public func managedObjectModel(name: String) -> NSManagedObjectModel {
        guard let URL = url(forResource: name, withExtension: Bundle.modelExtension),
            let model = NSManagedObjectModel(contentsOf: URL) else {
                preconditionFailure("Model not found or corrupted with name: \(name) in bundle: \(self)")
        }
        return model
    }
}
