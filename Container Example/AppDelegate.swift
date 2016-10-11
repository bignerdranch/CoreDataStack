//
//  AppDelegate.swift
//  Container Example
//
//  Created by Robert Edwards on 7/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let persistentContainer = NSPersistentContainer(name: "Container_Example")
    private let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    private lazy var loadingVC: UIViewController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("LoadingVC")
    }()
    private lazy var myCoreDataVC: MyCoreDataConnectedViewController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("CoreDataVC")
            as! MyCoreDataConnectedViewController // swiftlint:disable:this force_cast
    }()

    func applicationDidFinishLaunching(application: UIApplication) {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = loadingVC

        persistentContainer.loadPersistentStoresWithCompletionHandler() { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.seedInitialData()
            self.myCoreDataVC.persistentContainer = self.persistentContainer
            self.window?.rootViewController = self.myCoreDataVC
        }

        window?.makeKeyAndVisible()
    }

    private func seedInitialData() {
        let moc = persistentContainer.newBackgroundContext()
        moc.performBlockAndWait() {
            do {
                let bookCount = try Book.countInContext(moc)
                if bookCount == 0 {
                    let books = StubbedBookData.books
                    for bookTitle in books {
                        let book = Book(context: moc)
                        book.title = bookTitle
                    }

                    do {
                        try moc.save()
                    } catch {
                        fatalError("Saving records should not fail. Error: \(error)")
                    }
                }
            } catch {
                fatalError("Failed to fetch book count: \(error)")
            }
        }
    }
}
