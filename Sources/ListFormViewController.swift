//
//  ListFormViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore

public protocol ListFormViewController: class {

    var tableName: String { get }
    var dataSource: DataSource! { get }
    var selectedSegueIdentifier: String { get set }

    //func refresh()
}

let searchController = UISearchController(searchResultsController: nil)
extension ListFormViewController {

    func configureListFormView(_ view: UIView, _ record: AnyObject, _ indexPath: IndexPath) {
        // Give view information about records, let binding fill the UI components
        view.record = record

        let table = DataSourceEntry(dataSource: self.dataSource)
        table.indexPath = indexPath
        view.table = table
    }

    var defaultTableName: String {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)

        if let name = className.camelFirst {
            if NSClassFromString(name) != nil { // check entity
                return name
            }
        }
        logger.error("Looking for class \(className) to determine the type of records to load. But no class with this name found in the project. Check your data model.")
        abstractMethod(className: className)
    }

    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        guard let dataSource = dataSource else {
            return
        }
        if searchText.isEmpty {
            dataSource.predicate = nil
        } else {
            switch searchController.searchBar.selectedScopeButtonIndex {
            case 0:
                dataSource.predicate = NSPredicate(format: "entity.string contains[c] %@", searchText)
            case 1:
                dataSource.predicate = NSPredicate(format: "tag.name contains[c] %@", searchText)
            case 2:
                dataSource.predicate = NSPredicate(format: "book.authors.fullName contains[c] %@", searchText)
            default:
                dataSource.predicate = nil
            }
        }
    }

}

public protocol DataSourceSearchable: class, UISearchBarDelegate, UISearchControllerDelegate {

    var dataSource: DataSource! { get }
    var searchActive: Bool { get set }
    var searchableField: String { get }
}

fileprivate extension String {

    var camelFirst: String? {

        var newString: String = ""

        let upperCase = CharacterSet.uppercaseLetters
        var first = true
        for scalar in self.unicodeScalars {
            if first {
                first = false
            } else if upperCase.contains(scalar) {
                break
            }
            let character = Character(scalar)
            newString.append(character)

        }

        return newString
    }
}
