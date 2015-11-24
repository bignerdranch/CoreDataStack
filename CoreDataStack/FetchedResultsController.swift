//
//  FetchedResultsController.swift
//  CoreDataStack
//
//  Created by John Gallagher on 11/20/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

// NOTE: T should have a bound of `: NSManagedObject`, but that causes the Swift 2.0 compiler
// to fail with no useful error output upon switching on the enum. 
// Maybe in 2.1. :-( This is not a deal-breaker, because
// this enum in particular doesn't rely on T being an NSManagedObject.
/**
Enum representing the four types of object changes
a `FetchedResultsController` will notify you about.
*/
public enum FetchedResultsObjectChange<T> {
    /**
     Change type when an object is inserted.
     - parameter object: The inserted object of type `<T>`
     - parameter indexPath: The `NSIndexPath` of the new object
     */
    case Insert(object: T, indexPath: NSIndexPath)

    /**
     Change type when an object is deleted.
     - parameter object: The deleted object of type `<T>`
     - parameter indexPath: The previous `NSIndexPath` of the deleted object
     */
    case Delete(object: T, indexPath: NSIndexPath)

    /**
     Change type when an object is moved.
     - parameter object: The moved object of type `<T>`
     - parameter fromIndexPath: The `NSIndexPath` of the old location of the object
     - parameter toIndexPath: The `NSIndexPath` of the new location of the object
     */
    case Move(object: T, fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)

    /**
     Change type when an object is updated.
     - parameter object: The updated object of type `<T>`
     - parameter indexPath `NSIndexPath`: The `NSIndexPath` of the updated object
     */
    case Update(object: T, indexPath: NSIndexPath)
}

/**
 Enum representing the two type of secton changes
 a `FetchedResultsController` will notify you about.
 */
public enum FetchedResultsSectionChange<T: NSManagedObject> {
    /**
     Change type when a section is inserted.

     - parameter info: The inserted section's information
     - parameter index: The index where the section was inserted
     */
    case Insert(info: FetchedResultsSectionInfo<T>, index: Int)

    /**
     Change type when a section is deleted.

     - parameter info: The deleted section's information
     - parameter index: The previous index where the section was before being deleted
     */
    case Delete(info: FetchedResultsSectionInfo<T>, index: Int)
}

/**
 Protocol for delegate callbacks of Inserts, Deletes, Updates and Moves
 of `NSManagedObjects` as well as Inserts and Deletes of Sections.
 */
public protocol FetchedResultsControllerDelegate: class { // : class for weak capture
    /// Type of object being monitored. Must inherit from `NSManagedObject` and implement `CoreDataModelable`
    typealias T: NSManagedObject, CoreDataModelable

    /**
     Callback including all processed changes to objects

     - parameter controller: The `FetchedResultsController` posting the callback
     - parameter change: The type of change that occurred and all details see `FetchedResultsObjectChange`
     */
    func fetchedResultsController(controller: FetchedResultsController<T>,
        didChangeObject change: FetchedResultsObjectChange<T>)

    /**
     Callback including all processed changes to sections

     - parameter controller: The `FetchedResultsController` posting the callback
     - parameter change: The type of change that occurred and all details see `FetchedResultsSectionChange`
     */
    func fetchedResultsController(controller: FetchedResultsController<T>,
        didChangeSection change: FetchedResultsSectionChange<T>)

    /**
     Callback immediately before content will be changed

     - parameter controller: The `FetchedResultsController` posting the callback
     */
    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<T>)

    /**
     Callback immediately after content has been changed

     - parameter controller: The `FetchedResultsController` posting the callback
     */
    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<T>)

    /**
     Callback immediately after the fetch request has been executed

     - parameter controller: The `FetchedResultsController` posting the callback
     */
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<T>)
}

/**
 Section info used during the notification of a section being inserted or deleted.
 */
public struct FetchedResultsSectionInfo<T: NSManagedObject> {
    /// Array of objects belonging to the section.
    public let objects: [T]

    /// The name of the section
    public let name: String?

    /// The string used as an index title of the section
    public let indexTitle: String?

    private init(_ info: NSFetchedResultsSectionInfo) {
        objects = (info.objects as? [T]) ?? []
        name = info.name
        indexTitle = info.indexTitle
    }

    private init(_ info: FetchedResultsSectionInfo<T>, _ sortPredicate: (T, T) -> Bool) {
        objects = info.objects.sort(sortPredicate)
        name = info.name
        indexTitle = info.indexTitle
    }
}

/**
 A type safe wrapper around an `NSFetchedResultsController`
 */
public class FetchedResultsController<T: NSManagedObject where T: CoreDataModelable>: NSObject, NSFetchedResultsControllerDelegate {

    /// The `NSFetchRequest` being used by the `FetchedResultsController`
    public var fetchRequest: NSFetchRequest { return internalController.fetchRequest }
    /// The objects that match the fetch request
    public var fetchedObjects: [T]? { return internalController.fetchedObjects as? [T] }
    /// The first object matching the fetch request
    public var first: T? { return fetchedObjects?.first }
    /// The number of objects matching the fetch request
    public var count: Int { return fetchedObjects?.count ?? 0 }
    /// The sections returned by the `FetchedResultsController` see `FetchedResultsSectionInfo`
    public var sections: [FetchedResultsSectionInfo<T>]? {
        return internalController.sections.map { sections -> [FetchedResultsSectionInfo<T>] in
            (sections ).map { FetchedResultsSectionInfo<T>($0) }
        }
    }
    /// Subscript access to the sections
    public subscript(indexPath: NSIndexPath) -> T { return internalController.objectAtIndexPath(indexPath) as! T }
    /// The `NSIndexPath` for a specific object in the fetchedObjects
    public func indexPathForObject(object: T) -> NSIndexPath? { return internalController.indexPathForObject(object) }

    // MARK: - Lifecycle

    /**
    Initializer for the `FetchedResultsController`

    - parameter fetchRequest: The `NSFetchRequest` used to filter the objects displayed. Note the entityName must match the specialized type <T> of this class.
    - parameter context: The `NSManagedObjectContext` being observed for changes
    - parameter sectionNameKeyPath: An optional key path used for grouping results
    - parameter cacheName: An optional unique name used for caching results see `NSFetchedResultsController` for details
    */
    public init(fetchRequest: NSFetchRequest, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        assert(fetchRequest.entityName == T.entityName, "FetchResultsController created with incorrect NSFetchRequest entity type")

        internalController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        super.init()
        internalController.delegate = self
    }

    deinit {
        internalController.delegate = nil
    }

    // MARK: - Public Functions

    /**
    Function for setting the `FetchedResultsControllerDelegate` that will receive callback events.

    - parameter U: Your delegate must implement the methods in `FetchedResultsControllerDelegate` with the matching `CoreDataModelable` type that the `FetchedResultsController` is observing
    */
    public func setDelegate<U: FetchedResultsControllerDelegate where U.T == T>(delegate: U) {
        self.delegate = InternalFetchedResultsControllerDelegate(delegate)
    }

    /**
     Executes the fetch request tied to the `FetchedResultsController`

     - throws: Any errors produced by the `NSFetchResultsController`s `performFetch()` function.
     */
    public func performFetch() throws {
        defer {
            delegate?.didPerformFetch(self)
        }
        try internalController.performFetch()
    }

    // MARK: - Internal/Private Information

    private var delegate: InternalFetchedResultsControllerDelegate<T>?
    private let internalController: NSFetchedResultsController

    // MARK: - NSFetchedResultsControllerDelegate

    // Note: Normally these methods would be put in an extension, but @objc methods cannot be added to generic classes in an extension.

    @objc public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let object = anObject as! T

        let change: FetchedResultsObjectChange<T>
        switch type {
        case .Insert: change = .Insert(object: object, indexPath: newIndexPath!)
        case .Delete: change = .Delete(object: object, indexPath: indexPath!)
        case .Move:   change = .Move(object: object, fromIndexPath: indexPath!, toIndexPath: newIndexPath!)
        case .Update: change = .Update(object: object, indexPath: indexPath!)
        }

        delegate?.didChangeObject(self, change)
    }

    @objc public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let info = FetchedResultsSectionInfo<T>(sectionInfo)

        let change: FetchedResultsSectionChange<T>
        switch type {
        case .Insert: change = .Insert(info: info, index: sectionIndex)
        case .Delete: change = .Delete(info: info, index: sectionIndex)
        case .Move, .Update: fatalError("Invalid section change type reported by NSFetchedResultsController")
        }

        delegate?.didChangeSection(self, change)
    }

    @objc public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        delegate?.willChangeContent(self)
    }

    @objc public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        delegate?.didChangeContent(self)
    }
}

private struct InternalFetchedResultsControllerDelegate<T: NSManagedObject where T: CoreDataModelable> {
    let willChangeContent: ((FetchedResultsController<T>) -> Void)
    let didChangeContent: ((FetchedResultsController<T>) -> Void)
    let didChangeObject: ((FetchedResultsController<T>, FetchedResultsObjectChange<T>) -> Void)
    let didChangeSection: ((FetchedResultsController<T>, FetchedResultsSectionChange<T>) -> Void)
    let didPerformFetch: ((FetchedResultsController<T>) -> Void)

    init<U: FetchedResultsControllerDelegate where U.T == T>(_ delegate: U) {
        willChangeContent = { [weak delegate] in
            delegate?.fetchedResultsControllerWillChangeContent($0)
        }
        didChangeContent = { [weak delegate] in
            delegate?.fetchedResultsControllerDidChangeContent($0)
        }
        didChangeObject = { [weak delegate] in
            delegate?.fetchedResultsController($0, didChangeObject: $1)
        }
        didChangeSection = { [weak delegate] in
            delegate?.fetchedResultsController($0, didChangeSection: $1)
        }
        didPerformFetch = { [weak delegate] in
            delegate?.fetchedResultsControllerDidPerformFetch($0)
        }
    }
}
