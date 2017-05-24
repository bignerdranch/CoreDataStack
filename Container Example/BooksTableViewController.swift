//
//  BooksTableViewController.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 07/14/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import UIKit

import CoreData
import CoreDataStack

// swiftlint:disable weak_delegate (False positive)

class BooksTableViewController: UITableViewController {

    private var persistentContainer: NSPersistentContainer!
    private lazy var fetchedResultsController: FetchedResultsController<Book> = {
        let fetchRequest = NSFetchRequest<Book>()
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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GenericReuseCell")

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch objects: \(error)")
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(dismissViewController))
    }

    // MARK: - Actions

    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericReuseCell", for: indexPath)

        guard let sections = fetchedResultsController.sections else {
            fatalError("FetchedResultsController \(fetchedResultsController) should have sections, but found nil")
        }

        let section = sections[indexPath.section]
        let book = section.objects[indexPath.row]
        cell.textLabel?.text = book.title
        cell.isUserInteractionEnabled = false

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].indexTitle
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sections?.map() { $0.indexTitle ?? "" }
    }
}

class BooksFetchedResultsControllerDelegate: NSObject, FetchedResultsControllerDelegate {

    private weak var tableView: UITableView?

    // MARK: - Lifecycle

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<Book>) {
        tableView?.reloadData()
    }

    func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<Book>) {
        tableView?.beginUpdates()
    }

    func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<Book>) {
        tableView?.endUpdates()
    }

    func fetchedResultsController(_ controller: FetchedResultsController<Book>, didChangeObject change: FetchedResultsObjectChange<Book>) {
        guard let tableView = tableView else { return }
        switch change {
        case let .insert(_, indexPath):
            tableView.insertRows(at: [indexPath], with: .automatic)

        case let .delete(_, indexPath):
            tableView.deleteRows(at: [indexPath], with: .automatic)

        case let .move(_, fromIndexPath, toIndexPath):
            tableView.moveRow(at: fromIndexPath, to: toIndexPath)

        case let .update(_, indexPath):
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func fetchedResultsController(_ controller: FetchedResultsController<Book>, didChangeSection change: FetchedResultsSectionChange<Book>) {
        guard let tableView = tableView else { return }
        switch change {
        case let .insert(_, index):
            tableView.insertSections(IndexSet(integer: index), with: .automatic)

        case let .delete(_, index):
            tableView.deleteSections(IndexSet(integer: index), with: .automatic)
        }
    }
}
