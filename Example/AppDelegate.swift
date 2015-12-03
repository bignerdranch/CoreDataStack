//
//  AppDelegate.swift
//  Example
//
//  Created by Robert Edwards on 8/6/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import UIKit

import CoreDataStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var coreDataStack: CoreDataStack?
    private let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    private lazy var loadingVC: UIViewController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("LoadingVC")
    }()
    private lazy var myCoreDataVC: MyCoreDataConnectedViewController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("CoreDataVC")
            as! MyCoreDataConnectedViewController
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = loadingVC

        CoreDataStack.constructSQLiteStack(withModelName: "TestModel") { result in
            switch result {
            case .Success(let stack):
                self.coreDataStack = stack
                self.seedInitialData()

                // Note don't actually use dispatch_after
                // Arbitrary 2 second delay to illustrate an async setup.
                // dispatch_async(dispatch_get_main_queue()) {} should be used in production
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC))
                dispatch_after(delay, dispatch_get_main_queue()) {
                    self.myCoreDataVC.coreDataStack = stack
                    self.window?.rootViewController = self.myCoreDataVC
                }
            case .Failure(let error):
                assertionFailure("\(error)")
            }
        }

        window?.makeKeyAndVisible()

        return true
    }

    private func seedInitialData() {
        guard let stack = coreDataStack else {
            assertionFailure("Stack was not setup first")
            return
        }

        let moc = stack.newBackgroundWorkerMOC()
        do {
            try moc.performAndWaitOrThrow {
                let existingBooks = try Book.allInContext(moc)
                guard existingBooks.isEmpty else { return }
                let books = StubbedBookData.books
                for bookTitle in books {
                    let book = Book(managedObjectContext: moc)
                    book.title = bookTitle
                }
                try moc.saveContextAndWait()
            }
        } catch {
            print("Error creating inital data: \(error)")
        }
    }
}

