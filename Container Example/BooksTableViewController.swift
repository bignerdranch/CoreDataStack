//
//  BooksTableViewController.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 07/14/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import UIKit

import CoreData

// Remove me
import CoreDataStack

class BooksTableViewController: UITableViewController {

    private var persistentContainer: NSPersistentContainer!
    private lazy var fetchedResultsController: NSFetchedResultsController<Book> = {
        let fetchRequest = NSFetchRequest<Book>()
        fetchRequest.entity = Book.entity()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.persistentContainer.viewContext,
                                             sectionNameKeyPath: "firstInitial",
                                             cacheName: nil)
        frc.delegate = self.frcDelegate
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
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericReuseCell") ?? UITableViewCell()

        guard let sections = fetchedResultsController.sections else {
            fatalError("Sections missing")
        }

        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [Book] else {
            fatalError("Missing items")
        }

        let book = itemsInSection[indexPath.row]
        cell.textLabel?.text = book.title

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].indexTitle
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sections?.map() { $0.indexTitle ?? "" }
    }
}

class BooksFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

    private weak var tableView: UITableView?

    // MARK: - Lifecycle

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView?.insertRows(at: [indexPath!], with: .automatic)

        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .automatic)

        case .move:
            tableView?.moveRow(at: indexPath!, to: newIndexPath!)

        case .update:
            tableView?.reloadRows(at: [indexPath!], with: .automatic)
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView?.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .move, .update:
            tableView?.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        }
    }
}
