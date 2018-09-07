//
//  DataSourceSearchable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

public protocol DataSourceSearchable: class, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    var dataSource: DataSource! { get }

    var searchActive: Bool { get }
    var searchableField: String { get }
    var searchOperator: String { get }
    var searchSensitivity: String { get }
}

extension DataSourceSearchable {

    var isSearchBarMustBeHidden: Bool {
        // Hide if search field name is empty
        return searchableField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createSearchPredicate(_ searchText: String, table: Any?, valid: (Substring) -> Bool) -> NSPredicate? {
        var predicate: NSPredicate? = nil
        // need text to seach
        if !searchText.isEmpty {
            var searchableFields = searchableField.split(separator: ",")
            searchableFields = searchableFields.filter(valid) // remove invalid fields

            if searchableFields.isEmpty {
                assertionFailure("Configured field(s) to search '\(searchableField)' is not in table fields.\n Check search identifier list form storyboard for class \(self).\n Table: \((String(unwrappedDescrib: table)))")
            } else if searchableFields.count == 1, let searchableField = searchableFields.first {
                predicate = NSPredicate(format: "\(searchableField) \(searchOperator)[\(searchSensitivity)] %@", searchText)
            } else {
                var orPredicate: NSPredicate = .false
                for searchableField in searchableFields {
                    orPredicate = orPredicate || NSPredicate(format: "\(searchableField) \(searchOperator)[\(searchSensitivity)] %@", searchText)
                }
                predicate = orPredicate
            }
        }
        return predicate
    }
}
