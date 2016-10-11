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
class Book: NSManagedObject {

    @NSManaged var title: String?
    @NSManaged var authors: Set<Author>
    @NSManaged var publisher: NSManagedObject

    var firstInitial: String? {
        willAccessValueForKey("title")
        defer { didAccessValueForKey("title") }
        guard let title = title,
            let first = title.characters.first else {
                return nil
        }
        let initial = String(first)

        return initial
    }
}

extension Book: CoreDataModelable {
    static var entityName: String {
        return "Book"
    }
}
