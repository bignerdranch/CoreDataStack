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
        return self.mainStoryboard.instantiateViewController(withIdentifier: "LoadingVC")
    }()
    private lazy var myCoreDataVC: MyCoreDataConnectedViewController = {
        return self.mainStoryboard.instantiateViewController(withIdentifier: "CoreDataVC")
            as! MyCoreDataConnectedViewController
    }()

    func applicationDidFinishLaunching(_ application: UIApplication) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = loadingVC

        CoreDataStack.constructSQLiteStack(modelName: "UniqueConstraintModel") { result in
            switch result {
            case .success(let stack):
                self.coreDataStack = stack
                self.seedInitialData()

                // Note don't actually use dispatch_after
                // Arbitrary 2 second delay to illustrate an async setup.
                // dispatch_async(dispatch_get_main_queue()) {} should be used in production
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.myCoreDataVC.coreDataStack = stack
                    self.window?.rootViewController = self.myCoreDataVC
                }
            case .failure(let error):
                assertionFailure("\(error)")
            }
        }

        window?.makeKeyAndVisible()
    }

    private func seedInitialData() {
        guard let stack = coreDataStack else {
            assertionFailure("Stack was not setup first")
            return
        }

        let moc = stack.newChildContext()
        do {
            try moc.performAndWaitOrThrow {
                let books = StubbedBookData.books
                for bookTitle in books {
                    let book = Book(managedObjectContext: moc)
                    book.title = bookTitle
                }
                try moc.saveContextAndWait()
            }
        } catch {
            print("Error creating initial data: \(error)")
        }
    }
}
