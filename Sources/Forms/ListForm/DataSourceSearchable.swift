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

public protocol DataSourceSortable: DataSourceSearchable {

    var sortField: String { get }
    var sortAscending: Bool { get }
    var searchFieldAsSortField: Bool { get }
}

extension DataSourceSortable {

    var sortFields: [String] {
        return sortField.split(separator: ",").map { String($0) }
    }

    func makeSortDescriptors(tableInfo: DataStoreTableInfo?) -> [NSSortDescriptor] {
        var sortDescriptors: [NSSortDescriptor] = []
        guard let fields = tableInfo?.fields.filter({$0.type.isSortable}) else {
            // no table info, do the best we providen information
            if !sortField.isEmpty {
                sortDescriptors = sortFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
            } else if !searchableField.isEmpty && searchFieldAsSortField {
                sortDescriptors = searchableFields.map { NSSortDescriptor(key: String($0), ascending: sortAscending) }
            }
            return sortDescriptors
        }
        // if sort field
        if !sortField.isEmpty {
            sortDescriptors = sortFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
            if let sortDescriptors = filter(sortDescriptors: sortDescriptors, by: fields) {
                return sortDescriptors
            }
        }
        if !searchableField.isEmpty && searchFieldAsSortField {
            sortDescriptors = searchableFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
            if let sortDescriptors = filter(sortDescriptors: sortDescriptors, by: fields) {
                return sortDescriptors
            }
        }
        // XXX Find in UI Cell first/main field?

        // for the moment take the first in data store
        if let firstField = fields.first {
            logger.warning("There is no sort field for \(tableInfo?.name ?? "") list form. Please fill sortField.")
            sortDescriptors = [firstField.sortDescriptor(ascending: true)]
        } else {
            //assertionFailure("No sort field. Please fill sortField with a field name")
        }
        return sortDescriptors
    }

    /// remove if not sortable field
    private func filter(sortDescriptors: [NSSortDescriptor], by fields: [DataStoreFieldInfo]) -> [NSSortDescriptor]? {
        let sortDescriptors = sortDescriptors.filter {
            let name = $0.key
            return fields.contains { $0.name == name}
        }
        // if not empty return
        if !sortDescriptors.isEmpty {
            return sortDescriptors
        }
        return nil
    }

}

extension DataSourceSearchable {

    var searchableFields: [String] {
        return searchableField.split(separator: ",").map { String($0) }
    }

    var isSearchBarMustBeHidden: Bool {
        // Hide if search field name is empty
        return searchableField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createSearchPredicate(_ searchText: String, table: Any?, valid: (String) -> Bool) -> NSPredicate? {
        var predicate: NSPredicate?
        // need text to seach
        if !searchText.isEmpty {
            var searchableFields = self.searchableFields
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
