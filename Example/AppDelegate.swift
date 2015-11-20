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
                dispatch_async(dispatch_get_main_queue()) {
                    self.coreDataStack = stack
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
}

