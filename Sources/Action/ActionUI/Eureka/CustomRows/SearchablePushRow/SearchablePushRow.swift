//
//  SearchablePushRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/07/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import Eureka
import UIKit

open class _SearchSelectorViewController<Row: SelectableRowType, OptionsRow: OptionsProviderRow>: SelectorViewController<OptionsRow>, UISearchResultsUpdating, UISearchBarDelegate where Row.Cell.Value: SearchItem { // swiftlint:disable:this type_name

    let searchController = UISearchController(searchResultsController: nil)

    var originalOptions = [ListCheckRow<Row.Cell.Value>]()
    var currentOptions = [ListCheckRow<Row.Cell.Value>]()
    var scopeTitles: [String]?
    var showAllScope = true

    private let allScopeTitle = "All"
    open override func viewDidLoad() {
        super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false

        definesPresentationContext = true

        if let scopes = scopeTitles {
            searchController.searchBar.scopeButtonTitles = showAllScope ? [allScopeTitle] + scopes : scopes
            searchController.searchBar.delegate = self
        }

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        let searchTextField = searchController.searchBar.searchTextField
        let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor ?? UIColor.foreground
        searchTextField.textColor = navigationBarColor
        searchTextField.tintColor = navigationBarColor
        searchTextField.leftView?.tintColor = navigationBarColor
        searchTextField.rightView?.tintColor = navigationBarColor
        searchController.searchBar.tintColor = navigationBarColor
    }

    private func filterOptionsForSearchText(_ searchText: String, scope: String?) {
        if searchText.isEmpty {
            currentOptions = scope == nil ? originalOptions : originalOptions.filter { item in
                guard let value = item.selectableValue else { return false }
                return (scope == allScopeTitle) || value.matchesScope(scope!)
            }
        } else if scope == nil {
            currentOptions = originalOptions.filter { $0.selectableValue?.matchesSearchQuery(searchText) ?? false}
        } else {
            currentOptions = originalOptions.filter { item in
                guard let value = item.selectableValue else { return false }

                let doesScopeMatch = (scope == allScopeTitle) || value.matchesScope(scope!)
                return doesScopeMatch && value.matchesSearchQuery(searchText)
            }
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles?[searchBar.selectedScopeButtonIndex]

        filterOptionsForSearchText(searchBar.text ?? "", scope: scope)
        tableView.reloadData()
    }

    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterOptionsForSearchText(searchBar.text ?? "", scope: searchBar.scopeButtonTitles?[selectedScope])
        tableView.reloadData()
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentOptions.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = currentOptions[indexPath.row]
        option.updateCell()
        return option.baseCell
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentOptions[indexPath.row].didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    open override func setupForm(with options: [OptionsRow.OptionsProviderType.Option]) {
        super.setupForm(with: options)
        if let allRows = form.first?.map({ $0 }) as? [ListCheckRow<Row.Cell.Value>] {
            originalOptions = allRows
            currentOptions = originalOptions
        }
        tableView.reloadData()
    }
}

open class SearchSelectorViewController<OptionsRow: OptionsProviderRow>: _SearchSelectorViewController<ListCheckRow<OptionsRow.OptionsProviderType.Option>, OptionsRow> where OptionsRow.OptionsProviderType.Option: SearchItem {
}

open class _SearchPushRow<Cell: CellType>: SelectorRow<Cell> where Cell: BaseCell, Cell.Value: SearchItem { // swiftlint:disable:this type_name
    /// The scopes to use for additional filtering
    open var scopeTitles: [String]?

    /// If `true` show the All scope button, else hide it
    open var showAllScope = true

    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback {
            let svc = SearchSelectorViewController<SelectorRow<Cell>> { _ in }
            svc.scopeTitles = self.scopeTitles
            svc.showAllScope = self.showAllScope
            return  svc }, onDismiss: { viewController in _ = viewController.navigationController?.popViewController(animated: true)
        })
    }
}

public final class SearchPushRow<T: Equatable>: _SearchPushRow<PushSelectorCell<T>>, RowType where T: SearchItem {

    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public protocol SearchItem {
    func matchesSearchQuery(_ query: String) -> Bool
    func matchesScope(_ scopeName: String) -> Bool
}

extension SearchItem {
    func matchesScope(_ scopeName: String) -> Bool {
        return true
    }
}
