# BNR CoreData Stack - 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/BNRCoreDataStack.svg)](https://img.shields.io/cocoapods/v/BNRCoreDataStack.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](./LICENSE)

The BNR CoreData Stack is a small framework, written in Swift, that makes it easy to quickly set up a multi-threading ready CoreData stack.

## Requirements

- iOS 8.0+
- Xcode 7.0+
- Swift 2.0+

## Installation

### [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```
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

![Legend](./Resources/Legend.png)

### Nested Managed Object Context Stack Type

![Nested Managed Object Context Stack](./Resources/NestedMOC.png)

### Shared Persistent Store Coordinator Stack Type

![Thread Confined Managed Object Context Stack](./Resources/SharedPersistentStore.png)

### Shared Store Stack Type

![Shared Store Stack Type](./Resources/SharedStore.png)

### BNR Stack

![Thread Confined Managed Object Context Stack](./Resources/BNR_Stack.png)






