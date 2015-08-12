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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        CoreDataStack.constructStack(withModelName: "Example") { result in
            switch result {
            case .Success(let stack):
                self.coreDataStack = stack
                print("Success")
            case .Failure(let error):
                print(error)
                assertionFailure()
            }
        }

        return true
    }
}

