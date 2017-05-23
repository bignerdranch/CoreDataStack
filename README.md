# BNR Core Data Stack
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BNRCoreDataStack.svg)](https://cocoapods.org/pods/BNRCoreDataStack)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](./LICENSE)
[![Build Status](https://travis-ci.org/bignerdranch/CoreDataStack.svg)](https://travis-ci.org/bignerdranch/CoreDataStack)


The BNR Core Data Stack is a small framework, written in Swift, that makes it
both easier and safer to use Core Data. It does this by providing:

- [`FetchedResultsController<ManagedObjectType>`][src:frc] with:
    - A delegate having matching `ManagedObjectType`
    - Change events are an enum with associated data rather than a mess of
      optionals you have to unpack yourself
        - This includes workarounds for some misbehavior of Core Data that
          contradicts the documentation.
- An [`EntityMonitor<ManagedObjectType>`][src:em] that makes it easy to listen
  to all changes for a given `ManagedObjectType`.
- Extension methods on `ManagedObjectContext` that ensure saves happen on the right queue and that simplify various sorts of common interactions with the context.

  [src:frc]: ./Sources/FetchedResultsController.swift
  [src:em]: ./Sources/EntityMonitor.swift

[![Big Nerd Ranch](https://raw.githubusercontent.com/bignerdranch/CoreDataStack/master/Resources/logo.png)](http://bignerdranch.com)

For more details on the design methodology see: [Introducing the Big Nerd Ranch Core Data Stack](https://www.bignerdranch.com/blog/introducing-the-big-nerd-ranch-core-data-stack/)

For complete source documentation see: [Documentation](http://bignerdranch.github.io/CoreDataStack/index.html)

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
### Runtime:
Apps using BNR Core Data Stack can be used on devices running these versions
or later:

- macOS 10.10
- tvOS 9.0
- iOS 8.0

### Build Time:
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

Please see our [guide to contributing to the CoreDataStack](https://github.com/bignerdranch/CoreDataStack/tree/master/.github/CONTRIBUTING.md)




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

```
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
