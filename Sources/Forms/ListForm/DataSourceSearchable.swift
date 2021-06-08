//
//  DataSourceSearchable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences

import QMobileDataStore

public protocol DataSourceSearchable: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    /// The dataSource to search.
    var dataSource: DataSource? { get }

    /// Is search active?
    var searchActive: Bool { get set }
    /// Name(s) of the search field(s)
    var searchableField: String { get }
    /// Operator used to search. contains, beginswith,endswith. Default contains
    var searchOperator: String { get }
    /// Case sensitivity when searching. Default cd
    var searchSensitivity: String { get }

    /// Search scopes
    var searchScopes: [(String, NSPredicate)] { get } // orderred list

    /// When there is no more things to search, apply still a predicate (default: nil)
    var defaultSearchPredicate: NSPredicate? { get }
}

public protocol DataSourceSortable: DataSourceSearchable {

    /// Name of the field used to sort. (You use multiple field using coma)
    var sortField: String { get }
    /// Sort ascending on `sortField`
    var sortAscending: Bool { get }
    /// If no sort field, use search field as sort field
    var searchFieldAsSortField: Bool { get }
    /// Optional section for table using one field name
    var sectionFieldname: String? {get}
}

struct UserDataSourceSortable {
    @MutablePreference(key: "sortFields") static var sortFieldsByTable: [String: String]?

    static func getSortFields(for tableName: String) -> String? {
        let value = self.sortFieldsByTable?[tableName]
        logger.debug("Load from user setting sort order \(String(describing: value)) for \(tableName)")
        return value
    }

    private static func getSortFields(for dataSourceSortable: DataSourceSortable) -> String? {
        guard let dataSource = dataSourceSortable.dataSource else {
            logger.warning("Cannot load sort fields yet, no data source yet")
            assertionFailure("Cannot load sort fields yet, no data source yet")
            return nil
        }
        return getSortFields(for: dataSource.tableName)
    }

    static func setSortFields(for dataSourceSortable: DataSourceSortable, value: String) {
        guard let dataSource = dataSourceSortable.dataSource else {
            return
        }
        if self.sortFieldsByTable == nil {
            self.sortFieldsByTable = [:]
        }
        self.sortFieldsByTable?[dataSource.tableName] = value
    }
}

extension DataSourceSortable {

    var sortDescriptors: [NSSortDescriptor]? {
        get {
            return self.dataSource?.sortDescriptors
        }
        set {
            self.dataSource?.sortDescriptors = newValue
        }
    }

    func setSortDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
        let tableInfo: DataStoreTableInfo? = self.dataSource?.tableInfo
        guard let fields = tableInfo?.fields.filter({$0.type.isSortable}),
           let filtered = filter(sortDescriptors: sortDescriptors, by: fields),
           !filtered.isEmpty else {
            return
        }

        self.dataSource?.sortDescriptors = filtered
        let sortFieldAsString = sortDescriptors
            .map({ $0.ascending ? "\($0.key ?? "")" : "!\($0.key ?? "")" })
            .joined(separator: ",")
        UserDataSourceSortable.setSortFields(for: self, value: sortFieldAsString)
    }

    /// Compute the mandatory sort descriptors.
    func makeSortDescriptors(tableName: String) -> [NSSortDescriptor] {
        let tableInfo: DataStoreTableInfo? = self.dataSource?.tableInfo
        var sortDescriptors: [NSSortDescriptor] = []

        let sortFields: [String] = (UserDataSourceSortable.getSortFields(for: tableName) ?? self.sortField).split(separator: ",").map { String($0) }

        if !sortFields.isEmpty { // if sort field defined
            sortDescriptors = sortFields.map({ NSSortDescriptor(key: $0.noNot, ascending: $0.hasNot ? !sortAscending : sortAscending) })
        } else if !searchableField.isEmpty && searchFieldAsSortField {
            sortDescriptors = searchableFields.map { NSSortDescriptor(key: $0, ascending: sortAscending) }
        }

        // for the moment take the first in data store
        if sortDescriptors.isEmpty {
            if let sectionFieldname = self.sectionFieldname, !sectionFieldname.isEmpty {
                sortDescriptors = [NSSortDescriptor(key: sectionFieldname, ascending: sortAscending)]
            } else if let firstField = tableInfo?.fields.filter({$0.type.isSortable}).first {
                logger.warning("There is no valid sort field for \(tableInfo?.name ?? "") list form. Please fill sortField.")
                sortDescriptors = [firstField.sortDescriptor(ascending: true)]
            } else {
                // XXX Find in UI Cell first/main field?
                // assertionFailure("No sort field. Please fill sortField with a field name")
            }
        } else {
            if let sectionFieldname = self.sectionFieldname, !sectionFieldname.isEmpty { // Section must sorted first it seems
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

fileprivate extension String {
    /// if start with ! character
    var hasNot: Bool {
       return self.first == "!"
    }
    /// if start with ! character, remove it
    var noNot: String {
        if hasNot {
            return String(self.dropFirst())
        }
        return self
    }
}

import FileKit
struct SearchMapping {

    static var instance = SearchMapping()

    lazy var searchLocalizedMapping: [String: [String: String]] = {
        var result: [String: [String: String]] = [:]
        if let path = Bundle.main.path(forResource: "Formatters", ofType: "strings"),
           let strings: [String: String] = try? Dictionary(contentsOfPath: Path(path)) {
            for (key, value) in strings {
                if let index = key.firstIndex(of: "_") {
                    let startIndex: String.Index = key.startIndex
                    let field = String(key[startIndex..<index])
                    if result[field] == nil {
                        result[field] = [:]
                    }
                    result[field]?[value] = String(key[key.index(index, offsetBy: 1)..<key.endIndex])
                }
            }
        }
        return result
    }()
}

extension DataSourceSearchable {

    /// Return multiple search fields if defined in `searchableField` with separator `,`
    var searchableFields: [String] {
        return searchableField.split(separator: ",").map { String($0) }
    }

    // Hide if search field name is empty by default
    public var isSearchBarMustBeHidden: Bool {
        return searchableField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    fileprivate func createSearchPredicate(_ fieldsByName: [String: DataStoreFieldInfo], _ searchableField: String, _ searchText: String) -> NSPredicate {
        let searchPredicate: NSPredicate
        if case fieldsByName[searchableField]?.type = DataStoreFieldType.string {
            searchPredicate = NSPredicate(format: "(\(searchableField) \(searchOperator)[\(searchSensitivity)] %@)", searchText)
        } else {
            searchPredicate = NSPredicate(format: "(\(searchableField).stringValue \(searchOperator)[\(searchSensitivity)] %@)", searchText)
        }
        guard let forField = SearchMapping.instance.searchLocalizedMapping[searchableField], let newSearchText = forField[searchText] else {
            return searchPredicate
        }
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            searchPredicate,
            NSPredicate(format: "(\(searchableField) \(searchOperator)[\(searchSensitivity)] %@)", newSearchText)
        ])
    }

    func createSearchPredicate(_ searchText: String, tableInfo: DataStoreTableInfo?, predicates: [NSPredicate]) -> NSPredicate? {
        var predicates: [NSPredicate] = predicates
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
            var searchPredicate: NSPredicate?

            // Create predicate if there is one field or dev assert
            if searchableFields.isEmpty {
                assertionFailure("Configured field(s) to search '\(searchableField)' is not in table fields.\n Check search identifier list form storyboard for class \(self).\n Table: \((String(unwrappedDescrib: tableInfo)))")
            } else if searchableFields.count == 1, let searchableField = searchableFields.first {
                searchPredicate = createSearchPredicate(fieldsByName, searchableField, searchText)
            } else {
                let predicates: [NSPredicate] = searchableFields.map { searchableField in
                    return createSearchPredicate(fieldsByName, searchableField, searchText)
                }
                searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            }
            if let searchPredicate = searchPredicate {
                if predicates.isEmpty {
                    return searchPredicate // just to be faster
                }
                predicates.append(searchPredicate)
            }
        }

        // return the predicate
        if predicates.isEmpty {
            return nil
        } else if predicates.count == 1 {
            return predicates.first
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
