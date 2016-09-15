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
    let persistentContainer = NSPersistentContainer(name: "UniqueConstraintModel")
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

        persistentContainer.loadPersistentStores() { storeDescription, error in
            if let error = error as? NSError {
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
        moc.performAndWait() {
            if try! Book.countInContext(moc) == 0 {
                let books = StubbedBookData.books
                for bookTitle in books {
                    let book = Book(managedObjectContext: moc)
                    book.title = bookTitle
                }

                do {
                    try moc.save()
                } catch {
                    fatalError("Saving records should not fail. Error: \(error)")
                }
            }
        }
    }
}

