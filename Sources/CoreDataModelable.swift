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
        self.init(entity: Self.entityDescriptionInContext(context), insertIntoManagedObjectContext: context)
    }

    // MARK: - Finding Objects

    /**
    Creates an `NSEntityDescription` of the `CoreDataModelable` entity using the `entityName`

    - parameter context: `NSManagedObjectContext` to create the object within.

    - returns: `NSEntityDescription`: The entity description.
    */
    static public func entityDescriptionInContext(context: NSManagedObjectContext) -> NSEntityDescription! {
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else {
            assertionFailure("Entity named \(entityName) doesn't exist. Fix the entity description or naming of \(Self.self).")
            return nil
        }
        return entity
    }

    /**
     Creates a new fetch request for the `CoreDataModelable` entity.

     - parameter context: `NSManagedObjectContext` to create the object within.

     - returns: `NSFetchRequest`: The new fetch request.
     */
    static public func fetchRequestForEntity(inContext context: NSManagedObjectContext) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entityDescriptionInContext(context)
        return fetchRequest
    }

    /**
    Fetches the first Entity that matches the optional predicate within the specified `NSManagedObjectContext`.

    - parameter context: `NSManagedObjectContext` to find the entities within.
    - parameter predicate: An optional `NSPredicate` for filtering
    
    - throws: Any error produced from `executeFetchRequest`

    - returns: `Self?`: The first entity that matches the optional predicate or `nil`.
    */
    static public func findFirstInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil) throws -> Self? {
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
     - parameter predicate: An optional `NSPredicate` for filtering

     - throws: Any error produced from `executeFetchRequest`

     - returns: `[Self]`: The array of matching entities.
     */
    static public func allInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Self] {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        return try context.executeFetchRequest(fetchRequest) as! [Self]
    }
    
    // MARK: - Counting Objects
    
    /**
     Returns count of Entities that matches the optional predicate within the specified `NSManagedObjectContext`.
     
     - parameter context: `NSManagedObjectContext` to count the entities within.
     - parameter predicate: An optional `NSPredicate` for filtering
     
     - throws: Any error produced from `countForFetchRequest`
     
     - returns: `Int`: Count of entities that matches the optional predicate.
     */
    static public func countInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil) throws -> Int {
        let fetchReqeust = fetchRequestForEntity(inContext: context)
        fetchReqeust.includesSubentities = false
        fetchReqeust.predicate = predicate
        var error: NSError? = nil
        let count = context.countForFetchRequest(fetchReqeust, error: &error)
        if let error = error { throw error }
        guard count != NSNotFound else { return 0 }
        return count
    }

    // MARK: - Removing Objects

    /**
    Removes all entities from within the specified `NSManagedObjectContext`.

    - parameter context: `NSManagedObjectContext` to remove the entities from.
    
    - throws: Any error produced from `executeFetchRequest`
    */
    static public func removeAllInContext(context: NSManagedObjectContext) throws {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    /**
     Removes all entities from within the specified `NSManagedObjectContext` excluding a supplied array of entities.

     - parameter context: The `NSManagedObjectContext` to remove the Entities from.
     - parameter except: An Array of `NSManagedObjects` belonging to the `NSManagedObjectContext` to exclude from deletion.

     - throws: Any error produced from `executeFetchRequest`
     */
    static public func removeAllInContext(context: NSManagedObjectContext, except toKeep: [Self]) throws {
        let fetchRequest = fetchRequestForEntity(inContext: context)
        fetchRequest.predicate = NSPredicate(format: "NOT (self IN %@)", toKeep)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }

    // MARK: Private Funcs

    static private func removeAllObjectsReturnedByRequest(fetchRequest: NSFetchRequest, inContext context: NSManagedObjectContext) throws {
        // TODO: rcedwards A batch delete would be more efficient here on iOS 9 and up 
        //                  however it complicates things since the request requires a context with
        //                  an NSPersistentStoreCoordinator directly connected. (MOC cannot be a child of another MOC)
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities = false
        try context.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(context.deleteObject)
    }
}
