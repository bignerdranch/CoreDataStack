# BNR Core Data Stack
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BNRCoreDataStack.svg)](https://cocoapods.org/pods/BNRCoreDataStack)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](./LICENSE)
[![Build Status](https://travis-ci.org/bignerdranch/CoreDataStack.svg)](https://travis-ci.org/bignerdranch/CoreDataStack)


The BNR Core Data Stack is a small framework, written in Swift, that makes it easy to quickly set up a multi-threading ready Core Data stack.

For more details on the design methodology see: [Introducing the Big Nerd Ranch Core Data Stack](https://www.bignerdranch.com/blog/introducing-the-big-nerd-ranch-core-data-stack/)

For complete source documentation see: [Documentation](http://bignerdranch.github.io/CoreDataStack/index.html)

## Minimum Requirements

- OS X 10.10
- tvOS 9.0
- iOS 8.0
- Xcode 7.3
- Swift 2.2

## Installation

### [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```ruby
github "BigNerdRanch/CoreDataStack"
```

Then run `carthage update`.

Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

[carthage-installation]: https://github.com/Carthage/Carthage/blob/master/README.md

### [CocoaPods]

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

## <a id="usage"></a> Usage

### Constructing Your Stack

#### Import Framework

via: Carthage

```swift
import CoreDataStack
```

or via CocoaPods

```swift
import BNRCoreDataStack
```

#### <a id="sqlite_construct"></a> Standard SQLite Backed

```swift
CoreDataStack.constructSQLiteStack(withModelName: "TestModel") { result in
	switch result {
	case .Success(let stack):
		self.myCoreDataStack = stack
		print("Success")
	case .Failure(let error):
		print(error)
	}
}
```

#### In-Memory Only

```swift
do {
	myCoreDataStack = try CoreDataStack.constructInMemoryStack(withModelName: "TestModel")
} catch {
	print(error)
}
```

### Working with Managed Object Contexts

#### <a id="persisting_moc"></a> Private Persisting/Coordinator Connected Context

This is the root level context with a `PrivateQueueConcurrencyType` for asynchronous saving to the `NSPersistentStore`. Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.

```swift
myCoreDataStack.privateQueueContext
```

#### <a id="main_moc"></a> Main Queue / UI Layer Context

This is our `MainQueueConcurrencyType` context with its parent being the [private persisting context](#persisting_moc). This context should be used for any main queue or UI related tasks. Examples include setting up an `NSFetchedResultsController`, performing quick fetches, making UI related updates like a bookmark or favoriting an object. Performing a save() call on this context will automatically trigger a save on its parent via `NSNotification`.

```swift
myCoreDataStack.mainQueueContext
``` 

#### <a id="worker_moc"></a> Creating a Worker Context

Calling `newBackgroundWorkerMOC()` will vend us a `PrivateQueueConcurrencyType` child context of the [main queue context](#main_moc). Useful for any longer running task, such as inserting or updating data from a web service. Calling save() on this managed object context will automatically trigger a save on its parent context via `NSNotification`.

```swift
let workerContext = myCoreDataStack.newBackgroundWorkerMOC()
workerContext.performBlock() {
    // fetch data from web-service
    // update local data
    workerContext.saveContext()
}
```

#### Large Import Operation Context

In most cases, offloading your longer running work to a [background worker context](#worker_moc) will be sufficient in alleviating performance woes. If you find yourself inserting or updating thousands of objects then perhaps opting for a stand alone managed object context with a discrete persistent store like so would be the best option:

```swift
myCoreDataStack.newBatchOperationContext() { result in
    switch result {
    case .Success(let batchContext):
        // my big import operation
    case .Failure(let error):
        print(error)
    }
}
```

### Resetting The Stack

At times it can be necessary to completely reset your Core Data store and remove the file from disk, for example when a user logs out of your application. An instance of `CoreDataStack` can be reset by using the function 
`resetStore(resetCallback: CoreDataStackStoreResetCallback)`.


```swift
myCoreDataStack.resetStore() { result in
    switch result {
    case .Success:
        // proceed with fresh Core Data Stack
    case .Failure(let error):
        print(error)
    }
}
```

### Core Data Modelable Protocol

`CoreDataModelable` is a simple protocol that adds convenience methods on `NSManagedObject` subclasses. These methods make fetching, inserting, deleting, and change management easier.

#### Example

```swift
class Book: NSManagedObject, CoreDataModelable {
    static let entityName = "Book"
}

let allBooks = try Book.allInContext(moc)
let anyBook = try Book.findFirstInContext(moc)
try Book.removeAllInContext(moc)
```

### Type Safe Monitors

#### Fetched Results Controller

`FetchedResultsController<T>` is a type safe wrapper around `NSFetchedResultsController` using Swift generics.

##### Example

See [BooksTableViewController.swift](./Example/BooksTableViewController.swift) for an example.

#### Entity Monitor

`EntityMonitor<T>` is a class for monitoring inserts, deletes, and updates of a specific `NSManagedObject` subclass within an `NSManagedObjectContext`.

##### Example

See [EntityMonitorTests.swift](./CoreDataStackTests/EntityMonitorTests.swift) for an example.

## Contributing

Please see our [guide to contributing to the CoreDataStack](https://github.com/bignerdranch/CoreDataStack/tree/master/.github/CONTRIBUTING.md)

## Debugging Tips

To validate that you are honoring all of the threading rules it's common to add the following to a project scheme under `Run > Arguments > Arguments Passed On Launch`.

`-com.apple.CoreData.ConcurrencyDebug 1`

This will throw an exception if you happen to break a threading rule. For more on setting up Launch Arguments check out this [article by NSHipster](http://nshipster.com/launch-arguments-and-environment-variables/).

## About

[![Big Nerd Ranch](https://raw.githubusercontent.com/bignerdranch/CoreDataStack/master/Resources/logo.png)](http://bignerdranch.com)

- We [Develop][develop] custom apps for clients around the world.
- We [Teach][teach] immersive development bootcamps.
- We [Write][write] best-selling Big Nerd Ranch Guides.

[develop]: https://www.bignerdranch.com/we-develop/
[teach]: https://www.bignerdranch.com/we-teach/
[write]: https://www.bignerdranch.com/we-write/
