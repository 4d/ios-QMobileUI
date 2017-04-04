//
//  DataSourceSearchable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol DataSourceSearchable: class, UISearchBarDelegate, UISearchControllerDelegate {

    var dataSource: DataSource! { get }
    var searchActive: Bool { get set }
    var searchableField: String { get }

}
