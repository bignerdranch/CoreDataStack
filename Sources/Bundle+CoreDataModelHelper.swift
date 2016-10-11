//
//  Bundle+CoreDataModelHelper.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

extension NSBundle {
    static private let modelExtension = "momd"
    public func managedObjectModel(modelName: String) -> NSManagedObjectModel {
        guard let URL = URLForResource(modelName, withExtension: NSBundle.modelExtension),
            let model = NSManagedObjectModel(contentsOfURL: URL) else {
                preconditionFailure("Model not found or corrupted with name: \(modelName) in bundle: \(self)")
        }
        return model
    }
}
