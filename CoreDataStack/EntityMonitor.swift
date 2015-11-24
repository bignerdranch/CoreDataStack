//
//  EntityMonitor.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/18/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

/// The frequency of notification dispatch from the `EntityMonitor`
public enum FireFrequency {
    /// Notifications will be sent upon `NSManagedObjectContext` being changed
    case OnChange

    /// Notifications will be sent upon `NSManagedObjectContext` being saved
    case OnSave
}

/**
 Protocol for delegate callbacks of `NSManagedObject` entity change events.
 */
public protocol EntityMonitorDelegate: class { // : class for weak capture
    /// Type of object being monitored. Must inheirt from `NSManagedObject` and implement `CoreDataModelable`
    typealias T: NSManagedObject, CoreDataModelable

    /**
     Callback for when objects matching the predicate have been inserted

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of inserted matching objects
     */
    func entityMonitorObservedInserts(monitor: EntityMonitor<T>, entities: Set<T>)

    /**
     Callback for when objects matching the predicate have been deleted

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of deleted matching objects
     */
    func entityMonitorObservedDeletions(monitor: EntityMonitor<T>, entities: Set<T>)

    /**
     Callback for when objects matching the predicate have been updated

     - parameter monitor: The `EntityMonitor` posting the callback
     - parameter entities: The set of updated matching objects
     */
    func entityMonitorObservedModifications(monitor: EntityMonitor<T>, entities: Set<T>)
}

/**
 Class for monitoring changes within a given `NSManagedObjectContext`
    to a specific Core Data Entity with optional filtering via an `NSPredicate`.
 */
public class EntityMonitor<T: NSManagedObject where T: CoreDataModelable> {

    // MARK: - Public Properties

    /**
     Function for setting the `EntityMonitorDelegate` that will receive callback events.

     - parameter U: Your delegate must implement the methods in `EntityMonitorDelegate` with the matching `CoreDataModelable` type being monitored.
     */
    public func setDelegate<U: EntityMonitorDelegate where U.T == T>(delegate: U) {
        self.delegate = InternalEntityMonitorDelegate(delegate)
    }

    // MARK: - Private Properties

    private var delegate: InternalEntityMonitorDelegate<T>?

    private typealias EntitySet = Set<T>

    private let context: NSManagedObjectContext
    private let frequency: FireFrequency
    private let entityPredicate: NSPredicate
    private let filterPredicate: NSPredicate?
    private lazy var combinedPredicate: NSPredicate = {
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
    - parameter frequency: `FireFrequency` How frequently you wish to receive callbacks of changes. Default value is `.OnSave`.
    - parameter filterPredicate: An optional filtering predicate to be applied to entities being monitored.
    */
    public init?(context: NSManagedObjectContext, frequency: FireFrequency = .OnSave, filterPredicate: NSPredicate? = nil) {
        self.context = context
        self.frequency = frequency
        self.filterPredicate = filterPredicate
        guard let entity = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: context) else {
            entityPredicate = NSPredicate()
            return nil
        }

        entityPredicate = NSPredicate(format: "entity == %@", entity)
        setupObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Private

    private func setupObservers() {
        let notificationName: String
        switch frequency {
        case .OnChange:
            notificationName = NSManagedObjectContextObjectsDidChangeNotification
        case .OnSave:
            notificationName = NSManagedObjectContextDidSaveNotification
        }

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: ChangeObserverSelectorName,
            name: notificationName,
            object: context)
    }

    private func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - Notifications

    @objc private func evaluateChangeNotification(notification: NSNotification) {
        guard let changeSet = notification.userInfo else {
            return
        }

        context.performBlockAndWait() {
            if let inserted = changeSet[NSInsertedObjectsKey],
                filtered = inserted.filteredSetUsingPredicate(self.combinedPredicate)
                    as? EntitySet where filtered.count > 0 {
                        self.delegate?.objectsInserted(self, filtered)
            }

            if let deleted = changeSet[NSDeletedObjectsKey],
                filtered = deleted.filteredSetUsingPredicate(self.combinedPredicate)
                    as? EntitySet where filtered.count > 0 {
                       self.delegate?.objectsRemoved(self, filtered)
            }

            if let updated = changeSet[NSUpdatedObjectsKey],
                filtered = updated.filteredSetUsingPredicate(self.combinedPredicate)
                    as? EntitySet where filtered.count > 0 {
                        self.delegate?.objectsUpdated(self, filtered)
            }
        }
    }
}

private let ChangeObserverSelectorName: Selector = "evaluateChangeNotification:"

private struct InternalEntityMonitorDelegate<T: NSManagedObject where T: CoreDataModelable> {
    let objectsInserted: (EntityMonitor<T>, Set<T>) -> Void
    let objectsRemoved: (EntityMonitor<T>, Set<T>) -> Void
    let objectsUpdated: (EntityMonitor<T>, Set<T>) -> Void

    init<U: EntityMonitorDelegate where U.T == T>(_ delegate: U) {
        objectsInserted = { [weak delegate] in
            delegate?.entityMonitorObservedInserts($0, entities: $1)
        }
        objectsRemoved = { [weak delegate] in
            delegate?.entityMonitorObservedDeletions($0, entities: $1)
        }
        objectsUpdated = { [weak delegate] in
            delegate?.entityMonitorObservedModifications($0, entities: $1)
        }
    }
}
