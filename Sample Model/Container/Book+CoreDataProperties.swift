//
//  Book+CoreDataProperties.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/27/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData


extension Book {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Book");
    }

    @NSManaged public var title: String?
    @NSManaged public var authors: NSSet?
    @NSManaged public var publisher: Publisher?

}
