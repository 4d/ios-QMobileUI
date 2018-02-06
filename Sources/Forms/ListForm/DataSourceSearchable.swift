//
//  DataSourceSearchable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol DataSourceSearchable: class, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    var dataSource: DataSource! { get }
    var searchActive: Bool { get }
    var searchableField: String { get }

}

extension DataSourceSearchable {

    var isSearchBarMustBeHidden: Bool {
        // Hide if search field name is empty
        return searchableField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

}
