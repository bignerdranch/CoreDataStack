//
//  EntityMonitor.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import CoreData

/// The frequency of notification dispatch from the `EntityMonitor`
public enum FireFrequency {
    /// Notifications will be sent upon `NSManagedObjectContext` being changed
    case onChange

    /// Notifications will be sent upon `NSManagedObjectContext` being saved
    case onSave
}

/**
 Protocol for delegate callbacks of `NSManagedObject` entity change events.
 */
public protocol EntityMonitorDelegate: class { // : class for weak capture
    /// Type of object being monitored. Must inheirt from `NSManagedObject` and implement `NSFetchRequestResult`
    // swiftlint:disable type_name
    associatedtype T: NSManagedObject

    /**
     Callback for when objects matching the predicate have been inserted

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of inserted matching objects
     */
    func entityMonitorObservedInserts(_ monitor: EntityMonitor<T>, entities: Set<T>)

    /**
     Callback for when objects matching the predicate have been deleted

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of deleted matching objects
     */
    func entityMonitorObservedDeletions(_ monitor: EntityMonitor<T>, entities: Set<T>)

    /**
     Callback for when objects matching the predicate have been updated

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of updated matching objects
     */
    func entityMonitorObservedModifications(_ monitor: EntityMonitor<T>, entities: Set<T>)
}

/**
 Class for monitoring changes within a given `NSManagedObjectContext`
    to a specific Core Data Entity with optional filtering via an `NSPredicate`.
 */
public class EntityMonitor<T: NSManagedObject> {

    // MARK: - Public Properties

    /**
     Function for setting the `EntityMonitorDelegate` that will receive callback events.

     - parameter U: Your delegate must implement the methods in `EntityMonitorDelegate` with the matching `NSFetchRequestResult` type being monitored.
     */
    public func setDelegate<U: EntityMonitorDelegate>(_ delegate: U) where U.T == T {
        self.delegateHost = ForwardingEntityMonitorDelegate(owner: self, delegate: delegate)
    }

    // MARK: - Private Properties

    private var delegateHost: BaseEntityMonitorDelegate<T>? {
        willSet {
            delegateHost?.removeObservers()
        }
        didSet {
            delegateHost?.setupObservers()
        }
    }

    fileprivate typealias EntitySet = Set<T>
    fileprivate let frequency: FireFrequency
    fileprivate let context: NSManagedObjectContext

    private let entityPredicate: NSPredicate
    private let filterPredicate: NSPredicate?
    fileprivate lazy var combinedPredicate: NSPredicate = {
        if let filterPredicate = self.filterPredicate {
            return NSCompoundPredicate(andPredicateWithSubpredicates:
                [self.entityPredicate, filterPredicate])
        } else {
            return self.entityPredicate
        }
    }()

    // MARK: - Lifecycle

    /**
     Initializer to create an `EntityMonitor` to monitor changes to a specific Core Data Entity.

     This initializer is failable in the event your Entity is not within the supplied `NSManagedObjectContext`.

     - parameter context: `NSManagedObjectContext` the context you want to monitor changes within.
     - parameter entity: `NSEntityDescription` for the entity you wish to monitor
     - parameter frequency: `FireFrequency` How frequently you wish to receive callbacks of changes. Default value is `.OnSave`.

     - parameter filterPredicate: An optional filtering predicate to be applied to entities being monitored.
     */
    public init(context: NSManagedObjectContext, entity: NSEntityDescription,
                frequency: FireFrequency = .onSave, filterPredicate: NSPredicate? = nil) {
        self.context = context
        self.frequency = frequency
        self.filterPredicate = filterPredicate
        self.entityPredicate = NSPredicate(format: "entity == %@", entity)
        guard let entityClass = NSClassFromString(entity.managedObjectClassName) else {
            preconditionFailure("Entity Description is missing a class name or does not represent a class")
        }
        precondition(entityClass == T.self, "Class generic type must match entity descripton type")
    }

    deinit {
        delegateHost?.removeObservers()
    }
}

private class BaseEntityMonitorDelegate<T: NSManagedObject>: NSObject {

    private let changeObserverSelectorName = #selector(BaseEntityMonitorDelegate<T>.evaluateChangeNotification(_:))

    typealias Owner = EntityMonitor<T>
    typealias EntitySet = Owner.EntitySet

    unowned let owner: Owner

    init(owner: Owner) {
        self.owner = owner
    }

    final func setupObservers() {
        let notificationName: NSNotification.Name
        switch owner.frequency {
        case .onChange:
            notificationName = .NSManagedObjectContextObjectsDidChange
        case .onSave:
            notificationName = .NSManagedObjectContextDidSave
        }

        NotificationCenter.default.addObserver(self,
            selector: changeObserverSelectorName,
            name: notificationName,
            object: owner.context)
    }

    final func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        // swiftlint:disable:previous notification_center_detachment
    }

    @objc final func evaluateChangeNotification(_ notification: Notification) {
        guard let changeSet = (notification as NSNotification).userInfo else {
            return
        }

        owner.context.performAndWait { [predicate = owner.combinedPredicate] in
            func process(_ value: Any?) -> EntitySet {
                return (value as? NSSet)?.filtered(using: predicate) as? EntitySet ?? []
            }

            let inserted = process(changeSet[NSInsertedObjectsKey])
            let deleted = process(changeSet[NSDeletedObjectsKey])
            let updated = process(changeSet[NSUpdatedObjectsKey])
            self.handleChanges(inserted: inserted, deleted: deleted, updated: updated)
        }
    }

    func handleChanges(inserted: EntitySet, deleted: EntitySet, updated: EntitySet) {
        fatalError()
    }
}

private final class ForwardingEntityMonitorDelegate<Delegate: EntityMonitorDelegate>: BaseEntityMonitorDelegate<Delegate.T> {

    weak var delegate: Delegate?

    init(owner: Owner, delegate: Delegate) {
        super.init(owner: owner)
        self.delegate = delegate
    }

    override func handleChanges(inserted: EntitySet, deleted: EntitySet, updated: EntitySet) {
        guard let delegate = delegate else { return }

        if !inserted.isEmpty {
            delegate.entityMonitorObservedInserts(owner, entities: inserted)
        }

        if !deleted.isEmpty {
            delegate.entityMonitorObservedDeletions(owner, entities: deleted)
        }

        if !updated.isEmpty {
            delegate.entityMonitorObservedModifications(owner, entities: updated)
        }
    }
}
