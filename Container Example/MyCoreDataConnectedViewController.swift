//
//  MyCoreDataConnectedViewController.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 07/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import UIKit
import CoreData

class MyCoreDataConnectedViewController: UIViewController {
    var persistentContainer: NSPersistentContainer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        assert(persistentContainer != nil)
    }

    // MARK: - Actions
    @IBAction func showFRC(sender: UIButton) {
        let booksVC = BooksTableViewController(persistentContainer: persistentContainer)
        let navController = UINavigationController(rootViewController: booksVC)
        presentViewController(navController, animated: true, completion: nil)
    }
}
