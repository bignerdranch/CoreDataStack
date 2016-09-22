//
//  Bundle+CoreDataModelHelper.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

extension Bundle {
    static private let modelExtension = "momd"
    public func managedObjectModel(modelName: String) -> NSManagedObjectModel {
        guard let URL = url(forResource: modelName, withExtension: Bundle.modelExtension),
            let model = NSManagedObjectModel(contentsOf: URL) else {
                preconditionFailure("Model not found or corrupted with name: \(modelName) in bundle: \(self)")
        }
        return model
    }
}
