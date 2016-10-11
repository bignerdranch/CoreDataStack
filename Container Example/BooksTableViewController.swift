//
//  BooksTableViewController.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 07/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import UIKit

import CoreData

// Remove me
import CoreDataStack

class BooksTableViewController: UITableViewController {

    private var persistentContainer: NSPersistentContainer!
    private lazy var fetchedResultsController: FetchedResultsController<Book> = {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Book.entity()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let frc = FetchedResultsController<Book>(fetchRequest: fetchRequest,
            managedObjectContext: self.persistentContainer.viewContext,
            sectionNameKeyPath: "firstInitial")
        frc.setDelegate(self.frcDelegate)
        return frc
    }()

    private lazy var frcDelegate: BooksFetchedResultsControllerDelegate = {
        return BooksFetchedResultsControllerDelegate(tableView: self.tableView)
    }()

    // MARK: - Lifecycle

    init(persistentContainer: NSPersistentContainer) {
        super.init(nibName: nil, bundle: nil)
        self.persistentContainer = persistentContainer
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "GenericReuseCell")

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch objects: \(error)")
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,
            target: self,
            action: #selector(dismiss))
    }

    // MARK: - Actions

    @objc private func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GenericReuseCell") ?? UITableViewCell()

        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return cell
        }

        let section = sections[indexPath.section]
        let book = section.objects[indexPath.row]
        cell.textLabel?.text = book.title

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].indexTitle
    }

    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return fetchedResultsController.sections?.map() { $0.indexTitle ?? "" }
    }
}

class BooksFetchedResultsControllerDelegate: FetchedResultsControllerDelegate {

    private weak var tableView: UITableView?

    // MARK: - Lifecycle

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<Book>) {
        tableView?.reloadData()
    }

    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<Book>) {
        tableView?.beginUpdates()
    }

    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<Book>) {
        tableView?.endUpdates()
    }

    func fetchedResultsController(controller: FetchedResultsController<Book>,
        didChangeObject change: FetchedResultsObjectChange<Book>) {
            switch change {
            case let .Insert(_, indexPath):
                tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

            case let .Delete(_, indexPath):
                tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

            case let .Move(_, fromIndexPath, toIndexPath):
                tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)

            case let .Update(_, indexPath):
                tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
    }

    func fetchedResultsController(controller: FetchedResultsController<Book>,
        didChangeSection change: FetchedResultsSectionChange<Book>) {
            switch change {
            case let .Insert(_, index):
                tableView?.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)

            case let .Delete(_, index):
                tableView?.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
}
