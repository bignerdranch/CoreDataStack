//
//  MyCoreDataConnectedViewController.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 11/20/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import UIKit
import CoreDataStack

class MyCoreDataConnectedViewController: UIViewController {
    var coreDataStack: CoreDataStack!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        assert(coreDataStack != nil)
    }

    // MARK: - Actions
    @IBAction func showFRC(sender: UIButton) {
        let booksVC = BooksTableViewController(coreDataStack: coreDataStack)
        let navController = UINavigationController(rootViewController: booksVC)
        presentViewController(navController, animated: true, completion: nil)
    }
}