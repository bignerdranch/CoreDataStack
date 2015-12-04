//
//  CoreDataModelable.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

/**
 Protocol to be conformed to by `NSManagedObject` subclasses that allow for convenience
    methods that make fetching, inserting, deleting, and change management easier.
 */
public protocol CoreDataModelable {
    /**
     The name of your `NSManagedObject`'s entity within the `XCDataModel`.

     - returns: String: Entity's name in `XCDataModel`
     */
    static var entityName: String { get }
}

/**
 Extension to `CoreDataModelable` with convenience methods for
 creating, deleting, and fetching entities from a specific `NSManagedObjectContext`.
 */
extension CoreDataModelable where Self: NSManagedObject {

    // MARK: - Creating Objects

    /**
    Creates a new instance of the Entity within the specified `NSManagedObjectContext`.

    - parameter context: `NSManagedObjectContext` to create the object within.

    - returns: `Self`: The newly created entity.
    */
    public init(managedObjectContext context: NSManagedObjectContext) {
        self.init(entity: Self.entityInContext(context), insertIntoManagedObjectContext: context)
    }

    static func entityInContext(context: NSManagedObjectContext) -> NSEntityDescription! {
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else {
            assertionFailure("Entity named \(entityName) doesn't exist. Fix the entity description or naming of \(Self.self).")
            return nil
        }
        return entity
    }

    // MARK: - Finding Objects

    /**
    Fetches the first Entity that matches the optional predicate within the specified `NSManagedObjectContext`.

    - parameter predicate: An optional `NSPredicate` for filtering
    - parameter context: `NSManagedObjectContext` to find the entities within.
    
    - throws: Any error produced from `executeFetchRequest`

    - returns: `Self?`: The first entity that matches the optional predicate or `nil`.
    */
    static public func findFirst(predicate: NSPredicate?, context: NSManagedObjectContext) throws -> Self? {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = 1
        return try context.executeFetchRequest(fetchRequest).first as? Self
    }

    /**
     Fetches all Entities within the specified `NSManagedObjectContext`.

     - parameter context: `NSManagedObjectContext` to find the entities within.
     - parameter sortDescriptors: Optional array of `NSSortDescriptors` to apply to the fetch

     - throws: Any error produced from `executeFetchRequest`

     - returns: `[Self]`: The array of matching entities.
     */
    static public func allInContext(context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Self] {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        fetchRequest.sortDescriptors = sortDescriptors
        return try context.executeFetchRequest(fetchRequest) as! [Self]
    }

    // MARK: - Removing Objects

    /**
    Removes all entities from within the specified `NSManagedObjectContext`.

    - parameter context: `NSManagedObjectContext` to remove the entities from.
    
    - throws: Any error produced from `executeFetchRequest`
    */
    static public func removeAll(context: NSManagedObjectContext) throws {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    /**
     Removes all entities from within the specified `NSManagedObjectContext` excluding a supplied array of entities.

     - parameter toKeep: An Array of `NSManagedObjects` belonging to the `NSManagedObjectContext` to exclude from deletion.
     - parameter inContext: The `NSManagedObjectContext` to remove the Entities from.

     - throws: Any error produced from `executeFetchRequest`
     */
    static public func removeAllExcept(toKeep: [Self], inContext context: NSManagedObjectContext) throws {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        fetchRequest.predicate = NSPredicate(format: "NOT (self IN %@)", toKeep)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    // MARK: Private Funcs

    static private func removeAllObjectsReturnedByRequest(fetchRequest: NSFetchRequest, inContext context: NSManagedObjectContext) throws {
        // TODO: rcedwards A batch delete would be more efficient here on iOS 9 and up 
        //                  however it complicates things since the request requires a context with
        //                  an NSPersistentStoreCoordinator.
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities = false
        try context.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(context.deleteObject)
    }

    static private func fetchRequestForEntity(inContext context: NSManagedObjectContext) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entityInContext(context)
        return fetchRequest
    }
}
