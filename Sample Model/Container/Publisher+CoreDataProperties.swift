//
//  Publisher+CoreDataProperties.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/27/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation
import CoreData


extension Publisher {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Publisher");
    }

    @NSManaged public var name: String?
    @NSManaged public var books: NSSet?

}
