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
public enum FetchedResultsObjectChange<T> {
    case Insert(object: T, indexPath: NSIndexPath)
    case Delete(object: T, indexPath: NSIndexPath)
    case Move(object: T, fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    case Update(object: T, indexPath: NSIndexPath)
}

public struct FetchedResultsSectionInfo<T: NSManagedObject> {
    public let objects: [T]
    public let name: String?
    public let indexTitle: String?

    init(_ info: NSFetchedResultsSectionInfo) {
        objects = (info.objects as? [T]) ?? []
        name = info.name
        indexTitle = info.indexTitle
    }

    init(_ info: FetchedResultsSectionInfo<T>, _ sortPredicate: (T, T) -> Bool) {
        objects = info.objects.sort(sortPredicate)
        name = info.name
        indexTitle = info.indexTitle
    }
}

public enum FetchedResultsSectionChange<T: NSManagedObject> {
    case Insert(info: FetchedResultsSectionInfo<T>, index: Int)
    case Delete(info: FetchedResultsSectionInfo<T>, index: Int)
}

public protocol FetchedResultsControllerDelegate: class {
    typealias T: NSManagedObject, CoreDataModelable

    func fetchedResultsController(controller: FetchedResultsController<T>, didChangeObject change: FetchedResultsObjectChange<T>)
    func fetchedResultsController(controller: FetchedResultsController<T>, didChangeSection change: FetchedResultsSectionChange<T>)
    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<T>)
    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<T>)
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<T>)
}

public class FetchedResultsController<T: NSManagedObject where T: CoreDataModelable>: NSObject, NSFetchedResultsControllerDelegate {

    public var fetchRequest: NSFetchRequest { return internalController.fetchRequest }
    public var fetchedObjects: [T]? { return internalController.fetchedObjects as? [T] }
    public var first: T? { return fetchedObjects?.first }
    public var count: Int { return fetchedObjects?.count ?? 0 }
    public var sections: [FetchedResultsSectionInfo<T>]? {
        return internalController.sections.map { sections -> [FetchedResultsSectionInfo<T>] in
            (sections ).map { FetchedResultsSectionInfo<T>($0) }
        }
    }
    public subscript(indexPath: NSIndexPath) -> T { return internalController.objectAtIndexPath(indexPath) as! T }
    public func indexPathForObject(object: T) -> NSIndexPath? { return internalController.indexPathForObject(object) }
    private var delegate: InternalFetchedResultsControllerDelegate<T>?
    private let internalController: NSFetchedResultsController

    // MARK: - Lifecycle

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

    public func setDelegate<U: FetchedResultsControllerDelegate where U.T == T>(delegate: U) {
        self.delegate = InternalFetchedResultsControllerDelegate(delegate)
    }

    public func performFetch() throws {
        defer {
            delegate?.didPerformFetch(self)
        }
        try internalController.performFetch()
    }

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
