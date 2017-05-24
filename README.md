# BNR Core Data Stack
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/dt/BNRCoreDataStack.svg)](https://cocoapods.org/pods/BNRCoreDataStack)
[![GitHub license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](./LICENSE)
[![Build Status](https://travis-ci.org/bignerdranch/CoreDataStack.svg)](https://travis-ci.org/bignerdranch/CoreDataStack)

[![Big Nerd Ranch](https://raw.githubusercontent.com/bignerdranch/CoreDataStack/master/Resources/logo.png)](http://bignerdranch.com)


The BNR Core Data Stack is a small Swift framework
that makes it both easier and safer to use Core Data.


## A better fetched results controller and delegate
Our `FetchedResultsController<ManagedObjectType>`
sends Swifty delegate messages, rather than a mess of optionals.

Turn this:

```swift
func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChange anObject: Any,
    at indexPath: IndexPath?,
    for type: NSFetchedResultsChangeType,
    newIndexPath: IndexPath?
) {
    guard let book = anObject as? Book else {
        preconditionFailure("Why is this thing an Any anyway? WTH!")
    }

    switch type {
    case .insert:
        guard let newIndexPath = newIndexPath else {
            preconditionFailure("Insertion to nowheresville? WHY IS THIS OPTIONAL?")
        }

        print("We have a new book! \(book.title)")
        tableView?.insertRows(at: [newIndexPath], with: .automatic)

    case .delete:
        guard let indexPath = indexPath else {
            preconditionFailure("Deletion you say? Where? WHY IS THIS OPTIONAL?")
        }

        tableView?.deleteRows(at: [indexPath], with: .automatic)

    case .move:
        guard let newIndexPath = newIndexPath else {
            preconditionFailure("It moved to NOWHERE! WHY IS THIS OPTIONAL?")
        }
        guard let indexPath = indexPath else {
            preconditionFailure("It moved from NOWHERE?! WHY IS THIS OPTIONAL!")
        }

        tableView?.moveRow(at: indexPath, to: newIndexPath)

    case .update:
        guard let indexPath = indexPath else {
            preconditionFailure("I give up! Remind me, why are we using Swift, again?")
        }

        tableView?.reloadRows(at: [indexPath!], with: .automatic)
    }
}
```

Into this:

```swift
func fetchedResultsController(
    _ controller: FetchedResultsController<Book>,
    didChangeObject change: FetchedResultsObjectChange<Book>
) {
    switch change {
    case let .insert(book, indexPath):
        print("Hey look, it's not an Any! A new book: \(book.title)")
        tableView?.insertRows(at: [indexPath], with: .automatic)

    case let .delete(_ /*book*/, indexPath):
        print("A deletion, and it has a from-where? Finally!")
        tableView?.deleteRows(at: [indexPath], with: .automatic)

    case let .move(_ /*book*/, fromIndexPath, toIndexPath):
        print("Whoah, wait, I actually HAVE index paths? Both of them? Yay!")
        tableView?.moveRow(at: fromIndexPath, to: toIndexPath)

    case let .update(_ /*book*/, indexPath):
        print("It's almost like I'm actually using Swift and not Obj-C!")
        tableView?.reloadRows(at: [indexPath], with: .automatic)
    }
}
```

It also has properly typed sections and subscripting operators.
Because, we are writing Swift, are we not?

As a further bonus, you get our workarounds
for some misbehavior of Core Data that
contradicts the documentation, like this one:

```
// Work around a bug in Xcode 7.0 and 7.1 when running on iOS 8 - updated objects
// sometimes result in both an Update *and* an Insert call to didChangeObject,
// … (explanation continues) …
```


## Convenient store change listening
Our `EntityMonitor<ManagedObjectType>`
makes it easy to listen to all changes for a given `ManagedObjectType`:

```swift
/* EXAMPLE: NOTIFYING WHEN A MOC SAVES AUTHOR CHANGES */
let authorMonitor = EntityMonitor<Author>(context: moc, entity: authorEntityDescription, frequency: .onSave)
let authorMonitorDelegate = AuthorMonitorDelegate()
authorMonitor.setDelegate(authorMonitorDelegate)


/* EXAMPLE: AUTHOR MONITOR DELEGATE */
class AuthorMonitorDelegate: EntityMonitorDelegate {
    func entityMonitorObservedInserts(
        _ monitor: EntityMonitor<Author>,
        entities: Set<Author>
    ) {
        print("inserted authors:", entities)
    }

    func entityMonitorObservedModifications(
        _ monitor: EntityMonitor<Author>,
        entities: Set<Author>
    ) {
        print("modified authors:", entities)
    }

    func entityMonitorObservedDeletions(
        _ monitor: EntityMonitor<Author>,
        entities: Set<Author>
    ) {
        print("deleted authors:", entities)
    }
}
```


## A friendlier managed object context
Extension methods on `ManagedObjectContext` ensure
saves happen on the right queue
and make your life easier:

```swift
// Gotta catch 'em all
let allBooks = try Book.allInContext(moc)

// Or at least one of 'em
let anyBook = try Book.findFirstInContext(moc)

// Ah, forget it. Rocks fall, everyone dies.
try Book.removeAllInContext(moc)


// Blocking save, including up through parent contexts,
// on the appropriate queue.
try moc.saveContextToStoreAndWait()
```



## Interested?
Check out the [documentation!](http://bignerdranch.github.io/CoreDataStack/index.html)

For more details on the design methodology,
read ["Introducing the Big Nerd Ranch Core Data Stack."](https://www.bignerdranch.com/blog/introducing-the-big-nerd-ranch-core-data-stack/)


**Why "Stack"?**
Previously, the Core Data Stack provided a full, ready-made Core Data stack.
Apple now provide that themselves in `NSPersistentContainer`,
so we're free to focus on the other benefits listed above,
and we have [deprecated][#sec:deprecations] our own stack in favor of Apple's.

**Swift-Only:**
Note that the Core Data Stack is intended to be used from Swift.
Any use you can make of it from Objective-C is by luck, not design.



## Support
Big Nerd Ranch can [help you develop your app][bnr:dev],
or [train you or your team][bnr:teach] in Swift, iOS, and more.
We share what we learn here on GitHub and in [bookstores near you][bnr:books].

  [bnr:dev]: https://www.bignerdranch.com/work/
  [bnr:teach]: https://www.bignerdranch.com/training/
  [bnr:books]: https://www.bignerdranch.com/books/

For questions specific to the Core Data Stack, please
[open an issue](https://github.com/bignerdranch/CoreDataStack/issues/new).



## Minimum Requirements
### Running
Apps using BNR Core Data Stack can be used on devices running these versions
or later:

- macOS 10.10
- tvOS 9.0
- iOS 8.0

### Building
To build an app using BNR Core Data Stack, you'll need:

- Xcode 8.0
- Swift 3.0



## <a id="usage"></a> Usage

### Type Safe Monitors

#### Fetched Results Controller

`FetchedResultsController<T>` is a type safe wrapper around `NSFetchedResultsController` using Swift generics.

##### Example

See [BooksTableViewController.swift](./Example/BooksTableViewController.swift) for an example.

#### <a id="entity_monitor"></a> Entity Monitor

`EntityMonitor<T>` is a class for monitoring inserts, deletes, and updates of a specific `NSManagedObject` subclass within an `NSManagedObjectContext`.

##### Example
See [EntityMonitorTests.swift](./Tests/EntityMonitorTests.swift) for an example.

### NSManagedObject Extensions

`Adds convenience methods on `NSManagedObject` subclasses. These methods make fetching, inserting, deleting, and change management easier.

#### Example

```swift
let allBooks = try Book.allInContext(moc)
let anyBook = try Book.findFirstInContext(moc)
try Book.removeAllInContext(moc)
```



## Installation
### Installing with [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```ruby
github "BigNerdRanch/CoreDataStack"
```

Then run `carthage update`.

In your code, import the framework as `CoreDataStack`.

Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

[carthage-installation]: https://github.com/Carthage/Carthage/blob/master/README.md


### Installing with [CocoaPods]

[CocoaPods]: http://cocoapods.org

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'BNRCoreDataStack'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install`.

In your code, import the framework as `BNRCoreDataStack`.



## Contributing

Please see our [guide to contributing to the CoreDataStack](https://github.com/bignerdranch/CoreDataStack/tree/master/.github/CONTRIBUTING.md).




## Debugging Tips

To validate that you are honoring all of the threading rules it's common to add the following to a project scheme under `Run > Arguments > Arguments Passed On Launch`.

`-com.apple.CoreData.ConcurrencyDebug 1`

This will throw an exception if you happen to break a threading rule. For more on setting up Launch Arguments check out this [article by NSHipster](http://nshipster.com/launch-arguments-and-environment-variables/).



## Excluding sensitive data from iCloud and iTunes backups
The default store location will be backed up.
If you're storing sensitive information such as health records,
and perhaps if you're storing any personally identifiable information,
you should exclude the store from backup by flagging the URL on disk:

```swift
/* EXAMPLE: EXCLUDING A FILE FROM BACKUP */
var excludeFromBackup = URLResourceValues()
excludeFromBackup.isExcludedFromBackup = true

let someParentDirectoryURL: URL = …
var storeFileURL = URL(
    string: "MyModel.sqlite",
    relativeTo: someParentDirectoryURL)!
try! storeFileURL.setResourceValues(excludeFromBackup)
```

You then need to point your persistent container at that location:

```swift
/* EXAMPLE: AIMING YOUR CONTAINER AT A SPECIFIC URL */
// Ensure parent directory exists
try! FileManager.default.createDirectory(
    at: storeFileURL.deletingLastPathComponent(),
    withIntermediateDirectories: true)

// Configure the persistent container to use the specific URL
container.persistentStoreDescriptions = [
    NSPersistentStoreDescription(url: storeFileURL),
    ]
```

Prior to `NSPersistentContainer`, this would be done with Core Data Stack by:

```swift
/* EXAMPLE: DEPRECATED CORE DATA STACK WITH STORE URL */
CoreDataStack.constructSQLiteStack(
    withModelName: "MyModel",
    withStoreURL: storeFileURL) { result in
        switch result {
        case .success(let stack):
            // Use your new stack

        case .failure(let error):
            //handle error ...
        }
    }
```



## Deprecations
<!-- GitHub does this "fun" thing where it omits section fragment IDs on
mobile, so we provide our own ID to work around that. -->
<a id="sec:deprecations"></a>
### iOS 10.0 / macOS 10.12
- **Deprecated:** The [CoreDataStack](./Sources/CoreDataStack.swift) class itself.
    - **Replacement:** Use Apple's [NSPersistentContainer](https://developer.apple.com/reference/coredata/nspersistentcontainer) instead. The [Container Example](./Container Example/README.md) demonstrates how to use `NSPersistentContainer` with the BNR Core Data Stack.
- **Deprecated:** The [CoreDataModelable](./Sources/CoreDataModelable.swift) protocol.
    - **Replacement:** Use the type method [`NSManagedObject.entity()`](https://developer.apple.com/reference/coredata/nsmanagedobject/1640588-entity). Many of the convenience methods formerly available on `CoreDataModelable` are now offered by BNR Core Data Stack as extension methods on `NSManagedObject` as [`FetchHelpers`](./Sources/NSManagedObject+FetchHelpers.swift).
