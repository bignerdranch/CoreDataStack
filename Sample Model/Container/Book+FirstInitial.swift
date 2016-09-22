//
//  Book+FirstInitial.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 9/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

extension Book {
    var firstInitial: String? {
        willAccessValueForKey("title")
        defer { didAccessValueForKey("title") }
        guard let title = title,
            let first = title.characters.first else {
                return nil
        }
        let initial = String(first)

        return initial
    }

    func addAuthor(author: Author) {
        if let authors = authors {
            self.authors = authors.setByAddingObject(author)
        } else {
            authors = NSSet(set: [author])
        }
    }
}
