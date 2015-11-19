//
//  CoreDataModelable.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

/**
 Protocol to be conformed to by NSManagedObject subclasses that allow for convenience
    methods that make fetching, inserting, deleting, and change management easier.
 */
public protocol CoreDataModelable {
    /**
     The name of your NSManagedObject's entity within the XCDataModel.

     - returns: String: Entity's name in XCDataModel
     */
    static var entityName: String { get }
}

/**
 Extension to CoreDataModelable with convenience methods for 
 creating, deleting, and fetching entites from a specific NSManagedObjectContext.
 */
public extension CoreDataModelable where Self: NSManagedObject {

    // MARK: - Creating Objects

    /**
    Creates a new instance of the Entity within the specified NSManagedObjectContext.

    - parameter context: NSManagedObjectContext to create the object within.

    - returns: Self: The newly created entity.
    */
    static public func newInContext(context: NSManagedObjectContext) -> Self {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! Self
    }

    // MARK: - Finding Objects

    /**
    Fetches the first Entity that matches the optional predicate within the specified NSManagedObjectContext.

    - parameter predicate: An optional NSPredicate for filtering
    - parameter context: NSManagedObjectContext to find the entities within.

    - returns: Self: The first entity that matches the optional predicate.
    */
    static public func findFirst(predicate: NSPredicate?, context: NSManagedObjectContext) -> Self? {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate

        do {
            return try context.executeFetchRequest(fetchRequest).first as? Self
        } catch {
            return nil
        }
    }

    /**
     Fetches all Entities within the specified NSManagedObjectContext.

     - parameter context: NSManagedObjectContext to find the entities within.
     - parameter sortDescriptors: Optional array of NSSortDescriptors to apply to the fetch

     - returns: [Self]: The array of matching entities.
     */
    static public func allInContext(context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]? = nil) -> [Self] {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            return try context.executeFetchRequest(fetchRequest) as! [Self]
        } catch {
            return []
        }
    }

    // MARK: - Removing Objects

    /**
    Removes all entities from within the specified NSManagedObjectContext.

    - parameter context: NSManagedObjectContext to remove the entities from.
    */
    static public func removeAll(context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    /**
     Removes all entities from within the specified NSManagedObjectContext excluding a supplied array of entities.

     - parameter toKeep: An Array of NSManagedObjects belonging to the NSManagedObjectContext to exclude from deletion.
     - parameter inContext: The NSManagedObjectContext to remove the Entities from.
     */
    static public func removeAllExcept(toKeep: [Self], inContext context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "NOT (self IN %@)", toKeep)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    // MARK: Private Funcs

    static private func removeAllObjectsReturnedByRequest(fetchRequest: NSFetchRequest, inContext context: NSManagedObjectContext) throws {
        fetchRequest.includesPropertyValues = false

        try context.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(context.deleteObject)
    }
}
