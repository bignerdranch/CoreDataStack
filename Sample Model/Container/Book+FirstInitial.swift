//
//  Book+FirstInitial.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2015-2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

extension Book {
    var firstInitial: String? {
        willAccessValue(forKey: "title")
        defer { didAccessValue(forKey: "title") }
        guard let title = title,
            let first = title.characters.first else {
                return nil
        }
        let initial = String(first)

        return initial
    }

    func addAuthor(_ author: Author) {
        if let authors = authors {
            self.authors = NSSet(set: authors.adding(author))
        } else {
            authors = NSSet(set: [author])
        }
    }
}
