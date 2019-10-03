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

    var dataSource: DataSource? { get }

    var searchActive: Bool { get set }
    var searchableField: String { get }
    var searchOperator: String { get }
    var searchSensitivity: String { get }
}

public protocol DataSourceSortable: DataSourceSearchable {

    var sortField: String { get }
    var sortAscending: Bool { get }
    var searchFieldAsSortField: Bool { get }
    var sectionFieldname: String? {get}
}

extension DataSourceSortable {

    var sortFields: [String] {
        return sortField.split(separator: ",").map { String($0) }
    }

    func makeSortDescriptors(tableInfo: DataStoreTableInfo?) -> [NSSortDescriptor] {
        var sortDescriptors: [NSSortDescriptor] = []

        if !sortField.isEmpty { // if sort field defined
            sortDescriptors = sortFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
        } else if !searchableField.isEmpty && searchFieldAsSortField {
            sortDescriptors = searchableFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
        }

        // for the moment take the first in data store
        if sortDescriptors.isEmpty {
            if let sectionFieldname = self.sectionFieldname {
                sortDescriptors = [NSSortDescriptor(key: sectionFieldname, ascending: sortAscending)]
            } else if let firstField = tableInfo?.fields.filter({$0.type.isSortable}).first {
                logger.warning("There is no valid sort field for \(tableInfo?.name ?? "") list form. Please fill sortField.")
                sortDescriptors = [firstField.sortDescriptor(ascending: true)]
            } else {
                // XXX Find in UI Cell first/main field?
                //assertionFailure("No sort field. Please fill sortField with a field name")
            }
        } else {
            if let sectionFieldname = self.sectionFieldname { // Section must sorted first it seems
                sortDescriptors.insert(NSSortDescriptor(key: sectionFieldname, ascending: sortAscending), at: 0)
            }
            if let fields = tableInfo?.fields.filter({$0.type.isSortable}),
                let filtered = filter(sortDescriptors: sortDescriptors, by: fields) { // remove not valable sort field ie. field not exit in data model
                sortDescriptors = filtered
            }
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

    public var isSearchBarMustBeHidden: Bool {
        // Hide if search field name is empty
        return searchableField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createSearchPredicate(_ searchText: String, tableInfo: DataStoreTableInfo?) -> NSPredicate? {
        var predicate: NSPredicate?
        // need text to seach
        if !searchText.isEmpty {
            let fields = self.searchableFields
            var searchableFields: [String] = []

            // Filter if not exist in model, allow to not crash
            let fieldsByName = tableInfo?.fieldsByName ?? [:]
            let relationsByName = tableInfo?.relationshipsByName ?? [:]
            for field in fields {
                let fieldPath = field.split(separator: ".")
                if let firstField = fieldPath.first {
                    let first = String(firstField)
                    if fieldsByName[first] != nil {
                        searchableFields.append(first) // just field
                    } else if relationsByName[first] != nil {
                        searchableFields.append(field) // full path
                    }
                }
            }

            // Create predicate if there is one field or dev assert
            if searchableFields.isEmpty {
                assertionFailure("Configured field(s) to search '\(searchableField)' is not in table fields.\n Check search identifier list form storyboard for class \(self).\n Table: \((String(unwrappedDescrib: tableInfo)))")
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
