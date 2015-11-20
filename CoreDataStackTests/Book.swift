//
//  Book.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/27/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

@objc(Book)
class Book: NSManagedObject, CoreDataModelable {

    @NSManaged var title: String?
    @NSManaged var authors: Set<Author>

    // MARK: - CoreDataModelable

    static let entityName = "Book"
}
