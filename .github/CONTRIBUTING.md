# Contributing to the BNR Core Data Stack

We gladly welcome contributions from the community in the form of issues, suggestions, feature requests, and pull request.

## Issues

When opening a new issue please do the following:

### Search for Previous Issues

Search [closed issues](https://github.com/bignerdranch/coredatastack/issues?q=is%3Aissue+is%3Aclosed) to make sure your problem has not already been addressed.

Also look in [open issue](https://github.com/bignerdranch/coredatastack/issues) to avoid duplicates.

### New Issue

If you're unable to find an issue describing your problem create a [new issue](https://github.com/bignerdranch/coredatastack/issues/new) including the following:

* Title and Clear Description
* Relevant information
	* Output Log
	* Sample Code
	* Platform Context
	* Requested Outcome
	
### Labels

The following labels are used to help sort our open issues:

* **bug**
	* A defect in the current code.
* **duplicate**
	* Applied to issues that match an already created issues.
	* Apply this tag, link to other issue and close one.
* **enhancement**
	* A suggestion or feature request as an improvement to the project
* **help wanted**
	* An **enhancement** or **bug** we are actively looking for contributions from the community on
* **holding pattern**
	* An **enhancement** or **bug** we recognize as something to correct but are waiting for more information to present itself.
* **question**
	* A question regarding how something works.
* **upcoming release**
	* A **bug** fix or **enhancement** that is currently in master but not published as a [release](https://github.com/bignerdranch/CoreDataStack/releases)  

## Pull Request

Creating a patch for your issue is even better! The following guidelines should be used to ensure your patch is accepted.

### Style

Model your changes after the current projects coding style. As a reference the following [style guide](http://sportngin.github.io/styleguide/swift.html) is mostly inline with our project but may deviate in some places.

### Documentation

The [docs](https://bignerdranch.github.io/CoreDataStack) for CoreDataStack are thorough and we'd like to keep it that way. If you are contributing or modifying a public function, class, struct, enum, variable, etc. be sure to document using the [Swift Markup syntax](https://developer.apple.com/library/ios/documentation/Xcode/Reference/xcode_markup_formatting_ref/GeneralMarkupSyntax.html#//apple_ref/doc/uid/TP40016497-CH52-SW1). 

### Tests

Likewise, test coverage is equally important to us. When adding new features be sure to include new tests. If your patch is addressing a bug, consider adding a test that confirms your patch has resolved the issue.

### Git Best Practices

Write [good commit messages](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html):

* 50 char or less capitalized imperative title
* Optional more detailed body for context

Furthermore try and follow the guidelines in [deliberate git](http://rakeroutes.com/blog/deliberate-git/) when possible.

Prefer rebasing on top of master rather than merging master back into your feature branch.

### Pull Request Details

Include a clear title of what is being proposed, along with a description of the changes. Tag any relevant issues.



**Thanks! from [Big Nerd Ranch](https://www.bignerdranch.com)**
