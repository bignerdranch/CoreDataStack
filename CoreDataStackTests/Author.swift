//
//  Author.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 4/27/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData

@objc(Author)
class Author: NSManagedObject {

    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var books: NSSet

    class func newAuthorInContext(context: NSManagedObjectContext) -> Author {
        return NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: context) as! Author
    }

    class func allAuthorsInContext(context: NSManagedObjectContext) -> [Author] {
        let fr = NSFetchRequest(entityName: "Author")
        return context.executeFetchRequest(fr, error: nil) as! [Author]
    }
}
