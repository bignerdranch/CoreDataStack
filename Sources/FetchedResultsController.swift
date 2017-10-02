//
//  FetchedResultsController.swift
//  CoreDataStack
//
//  Created by John Gallagher on 11/20/15.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

// swiftlint:disable line_length

import CoreData

#if os(iOS) || os(watchOS) || os(tvOS)

    /**
     Enum representing the four types of object changes
     a `FetchedResultsController` will notify you about.
     */
    /**
     Change type when an object is inserted.
     - parameter object: The inserted object of type `<T>`
     - parameter indexPath: The `NSIndexPath` of the new object
     */
    public enum FetchedResultsObjectChange<T: NSManagedObject> {
        case insert(object: T, indexPath: IndexPath)

        /**
         Change type when an object is deleted.
         - parameter object: The deleted object of type `<T>`
         - parameter indexPath: The previous `NSIndexPath` of the deleted object
         */
        case delete(object: T, indexPath: IndexPath)

        /**
         Change type when an object is moved.
         - parameter object: The moved object of type `<T>`
         - parameter fromIndexPath: The `NSIndexPath` of the old location of the object
         - parameter toIndexPath: The `NSIndexPath` of the new location of the object
         */
        case move(object: T, fromIndexPath: IndexPath, toIndexPath: IndexPath)

        /**
         Change type when an object is updated.
         - parameter object: The updated object of type `<T>`
         - parameter indexPath `NSIndexPath`: The `NSIndexPath` of the updated object
         */
        case update(object: T, indexPath: IndexPath)
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
        case insert(info: FetchedResultsSectionInfo<T>, index: Int)

        /**
         Change type when a section is deleted.

         - parameter info: The deleted section's information
         - parameter index: The previous index where the section was before being deleted
         */
        case delete(info: FetchedResultsSectionInfo<T>, index: Int)
    }

    /**
     Protocol for delegate callbacks of Inserts, Deletes, Updates and Moves
     of `NSManagedObjects` as well as Inserts and Deletes of Sections.
     */
    public protocol FetchedResultsControllerDelegate: class { // : class for weak capture
        /// Type of object being monitored. Must inherit from `NSManagedObject` and implement `CoreDataModelable`
        // swiftlint:disable type_name
        associatedtype T: NSManagedObject

        /**
         Callback including all processed changes to objects

         - parameter controller: The `FetchedResultsController` posting the callback
         - parameter change: The type of change that occurred and all details see `FetchedResultsObjectChange`
         */
        func fetchedResultsController(_ controller: FetchedResultsController<T>,
                                      didChangeObject change: FetchedResultsObjectChange<T>)

        /**
         Callback including all processed changes to sections

         - parameter controller: The `FetchedResultsController` posting the callback
         - parameter change: The type of change that occurred and all details see `FetchedResultsSectionChange`
         */
        func fetchedResultsController(_ controller: FetchedResultsController<T>,
                                      didChangeSection change: FetchedResultsSectionChange<T>)

        /**
         Callback immediately before content will be changed

         - parameter controller: The `FetchedResultsController` posting the callback
         */
        func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<T>)

        /**
         Callback immediately after content has been changed

         - parameter controller: The `FetchedResultsController` posting the callback
         */
        func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<T>)

        /**
         Callback immediately after the fetch request has been executed

         - parameter controller: The `FetchedResultsController` posting the callback
         */
        func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<T>)
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

        fileprivate init(_ info: NSFetchedResultsSectionInfo) {
            objects = (info.objects as? [T]) ?? []
            name = info.name
            indexTitle = info.indexTitle
        }
    }

    /**
     A type safe wrapper around an `NSFetchedResultsController`
     */
    public class FetchedResultsController<T: NSManagedObject> {

        /// The `NSFetchRequest` being used by the `FetchedResultsController`
        public var fetchRequest: NSFetchRequest<T> { return internalController.fetchRequest }
        /// The objects that match the fetch request
        public var fetchedObjects: [T]? { return internalController.fetchedObjects }
        /// The first object matching the fetch request
        public var first: T? { return fetchedObjects?.first }
        /// The number of objects matching the fetch request
        public var count: Int { return fetchedObjects?.count ?? 0 }
        /// The number of sections matching the fetch request
        public var sectionCount: Int { return sections?.count ?? 0 }
        /// The sections returned by the `FetchedResultsController` see `FetchedResultsSectionInfo`
        public var sections: LazyMapCollection<[NSFetchedResultsSectionInfo], FetchedResultsSectionInfo<T>>? {
            guard let sections = internalController.sections else {
                return nil
            }
            return sections.lazy.map(FetchedResultsSectionInfo<T>.init)
        }
        /// The name of the file used to cache section information.
        public var cacheName: String? { return internalController.cacheName }
        /// Subscript access to the sections
        public subscript(indexPath: IndexPath) -> T { return internalController.object(at: indexPath) }
        /// The `NSIndexPath` for a specific object in the fetchedObjects
        public func indexPathForObject(_ object: T) -> IndexPath? { return internalController.indexPath(forObject: object) }

        // MARK: - Lifecycle

        /**
         Initializer for the `FetchedResultsController`

         - parameter fetchRequest: The `NSFetchRequest` used to filter the objects displayed. Note the entityName must match the specialized type <T> of this class.
         - parameter context: The `NSManagedObjectContext` being observed for changes
         - parameter sectionNameKeyPath: An optional key path used for grouping results
         - parameter cacheName: An optional unique name used for caching results see `NSFetchedResultsController` for details
         */
        public init(fetchRequest: NSFetchRequest<T>, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
            internalController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        }

        deinit {
            // Core Data does not yet use weak references for delegates; the
            // delegate must be nilled out for thread safety reasons.
            internalController.delegate = nil
        }

        // MARK: - Public Functions

        /**
         Function for setting the `FetchedResultsControllerDelegate` that will receive callback events.

         - parameter U: Your delegate must implement the methods in `FetchedResultsControllerDelegate` with the matching `CoreDataModelable` type that the `FetchedResultsController` is observing
         */
        public func setDelegate<U: FetchedResultsControllerDelegate>(_ delegate: U) where U.T == T {
            self.delegateHost = ForwardingFetchedResultsControllerDelegate<U>(owner: self, delegate: delegate)
        }

        /**
         Executes the fetch request tied to the `FetchedResultsController`

         - throws: Any errors produced by the `NSFetchResultsController`s `performFetch()` function.
         */
        public func performFetch() throws {
            defer {
                delegateHost?.fetchedResultsControllerDidPerformFetch()
            }
            try internalController.performFetch()
        }

        // MARK: - Internal/Private Information

        private let internalController: NSFetchedResultsController<T>
        private var delegateHost: BaseFetchedResultsControllerDelegate<T>? {
            didSet {
                internalController.delegate = delegateHost
            }
        }
    }

    private extension FetchedResultsObjectChange {
        init?(object: AnyObject, indexPath: IndexPath?, changeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            guard let object = object as? T else { return nil }
            switch (type, indexPath, newIndexPath) {
            case (.insert, _?, _):
                // Work around a bug in Xcode 7.0 and 7.1 when running on iOS 8 - updated objects
                // sometimes result in both an Update *and* and Insert call to didChangeObject, which
                // makes no sense. Thankfully the bad Inserts have a non-nil "old" indexPath (which
                // also makes no sense) - we check for that here and ignore those erroneous messages.
                // For more discussion, see https://forums.developer.apple.com/thread/12184
                return nil

            case let (.insert, nil, newIndexPath?):
                self = .insert(object: object, indexPath: newIndexPath)

            case let (.delete, indexPath?, nil):
                self = .delete(object: object, indexPath: indexPath)

            case let (.update, indexPath?, _):
                // in pre iOS 9 runtimes a newIndexPath value is also passed in
                self = .update(object: object, indexPath: indexPath)

            case let (.move, fromIndexPath?, toIndexPath?):
                // There are at least two different .Move-related bugs running on Xcode 7.3.1:
                //
                // * iOS 8.4 sometimes reports both an .Update and a .Move (with identical index paths)
                //   for the same object.
                // * iOS 9.3 sometimes reports _just_ a .Move (with identical index paths) and no
                //   .Update for an object.
                //
                // According to https://developer.apple.com/library/ios/releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/
                // we shouldn't get moves with identical index paths, but we have to work around
                // this somehow. For now, we'll convert identical-indexPath-.Moves into .Updates
                // (just like that document claims NSFetchedResultsController does). This means we'll
                // get correct behavior on iOS 9.3. iOS 8.4 will get "double updates" sometimes, but
                // _hopefully_ that's ok.
                if fromIndexPath == toIndexPath {
                    self = .update(object: object, indexPath: fromIndexPath)
                } else {
                    self = .move(object: object, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath)
                }

            default:
                preconditionFailure("Invalid change. Missing a required index path for corresponding change type.")
            }
        }
    }

    fileprivate extension FetchedResultsSectionChange {
        init(section sectionInfo: NSFetchedResultsSectionInfo, index sectionIndex: Int, changeType type: NSFetchedResultsChangeType) {
            let info = FetchedResultsSectionInfo<T>(sectionInfo)
            switch type {
            case .insert:
                self = .insert(info: info, index: sectionIndex)
            case .delete:
                self = .delete(info: info, index: sectionIndex)
            case .move, .update:
                preconditionFailure("Invalid section change type reported by NSFetchedResultsController")
            }
        }
    }

    private class BaseFetchedResultsControllerDelegate<T>: NSObject, NSFetchedResultsControllerDelegate {
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            fatalError()
        }

        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            fatalError()
        }

        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any, at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?
        ) {
            fatalError()
        }

        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange sectionInfo: NSFetchedResultsSectionInfo,
            atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType
        ) {
            fatalError()
        }

        func fetchedResultsControllerDidPerformFetch() {
            fatalError()
        }
    }

    private final class ForwardingFetchedResultsControllerDelegate<Delegate: FetchedResultsControllerDelegate>: BaseFetchedResultsControllerDelegate<Delegate.T> {
        typealias Owner = FetchedResultsController<Delegate.T>

        weak var delegate: Delegate?
        unowned let owner: Owner

        init(owner: Owner, delegate: Delegate) {
            self.delegate = delegate
            self.owner = owner
        }

        override func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            delegate?.fetchedResultsControllerWillChangeContent(owner)
        }

        override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            delegate?.fetchedResultsControllerDidChangeContent(owner)
        }

        override func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any, at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?
        ) {
            guard let object = anObject as? Delegate.T else { return }
            guard let change = FetchedResultsObjectChange<Delegate.T>(object: object, indexPath: indexPath,
                                                                      changeType: type, newIndexPath: newIndexPath) else { return }
            delegate?.fetchedResultsController(owner, didChangeObject: change)
        }

        override func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange sectionInfo: NSFetchedResultsSectionInfo,
            atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType
        ) {
            let change = FetchedResultsSectionChange<Delegate.T>(section: sectionInfo, index: sectionIndex, changeType: type)
            delegate?.fetchedResultsController(owner, didChangeSection: change)
        }

        override func fetchedResultsControllerDidPerformFetch() {
            delegate?.fetchedResultsControllerDidPerformFetch(owner)
        }
    }

#endif
