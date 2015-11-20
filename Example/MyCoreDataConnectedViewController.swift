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

    override func viewDidLoad() {
        assert(coreDataStack != nil)
    }
}