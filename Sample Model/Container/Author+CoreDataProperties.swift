//
//  Author+CoreDataProperties.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/27/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData


extension Author {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Author");
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var books: NSSet?

}
