//
//  ListFormSearchable.swift
//  QMobileUI
//
//  Created by phimage on 11/12/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

public protocol ListFormSearchable: ListForm/*, DataSourceSearchable*/ {
    /// The associated search bar
    var searchBar: UISearchBar! { get set }
    /// Add search bar in place of navigation bar title
    var searchableAsTitle: Bool { get }
    /// Keep search bar if scrolling (only if searchableAsTitle = false)
    var searchableWhenScrolling: Bool { get }
    /// Hide navigation bar when searching (only if searchableAsTitle = false)
    var searchableHideNavigation: Bool { get }
    /// Activate search with code scanner
    var searchUsingCodeScanner: Bool { get }
    /// open the detail form is search result is only one record
    var searchOpenIfOne: Bool { get set }

    func onSearchBegin()
    func onSearchButtonClicked()
    func onSearchFetching()
    func onSearchCancel()
    func onSearchCodeScanClicked()
}

extension ListFormSearchable where Self: UIViewController {

    func installNatigationMenu() {
        if #available(iOS 13.0, *) {
            /*if let titleView = self.navigationBarTitleView {
                let interaction = UIContextMenuInteraction(delegate: self)
                titleView.addInteraction(interaction)
                titleView.isUserInteractionEnabled = true
            } else {
                logger.debug("Cannot get navigation bar title for \(self)")
            }*/
        } // else Fallback on earlier versions
    }

    func doInstallSearchBar() {
       var searchBar = self.searchBar
        // Install seachbar into navigation bar if any
        if !isSearchBarMustBeHidden {
            if searchBar?.superview == nil {
                if searchableAsTitle {
                    self.navigationItem.titleView = searchBar
                } else {
                    let searchController = UISearchController(searchResultsController: nil)
                    searchController.searchResultsUpdater = self
                    searchController.obscuresBackgroundDuringPresentation = false
                    searchController.hidesNavigationBarDuringPresentation = searchableHideNavigation
                    searchController.delegate = self
                    self.definesPresentationContext = true
                    self.navigationItem.searchController = searchController
                    self.navigationItem.hidesSearchBarWhenScrolling = !searchableWhenScrolling
                    self.definesPresentationContext = true

                    searchController.searchBar.copyAppearance(from: self.searchBar)
                    self.searchBar = searchController.searchBar // continue to manage search using listener
                    searchBar = self.searchBar

                    if let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor { // XXX I do not find another way, this not restrict change to this controller...
                        let appearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
                        appearance.defaultTextAttributes = [NSAttributedString.Key.foregroundColor: navigationBarColor]
                    }
                }
            }
        }
        if self.searchUsingCodeScanner {
            self.searchBar?.showsBookmarkButton = true
            self.searchBar?.setImage(UIImage(systemName: "qrcode"), for: .bookmark, state: .normal)
        }
        if let searchTextField = searchBar?.searchTextField, let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor ?? searchTextField.textColor {
            //if !searchableAsTitle {
            searchTextField.textColor = navigationBarColor
            //}
            searchTextField.tintColor = navigationBarColor
            searchTextField.leftView?.tintColor = navigationBarColor
            searchTextField.rightView?.tintColor = navigationBarColor
        }
        searchBar?.delegate = self

        if isSearchBarMustBeHidden {
            searchBar?.isHidden = true
        }
    }

    func performSearch(_ searchText: String) {
        if !isSearchBarMustBeHidden {
            // Create the search predicate
            dataSource?.predicate = createSearchPredicate(searchText, tableInfo: tableInfo)

            // Event
            onSearchFetching()
        }
        // XXX API here could load more from network
    }

    func do_searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // XXX could add other predicate
        searchBar.showsCancelButton = true
        performSearch(searchText)
    }

    func do_searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        onSearchBegin()
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func do_searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.endEditing(true)
        onSearchButtonClicked()
    }

    func do_searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: false)
        searchBar.endEditing(true)
        dataSource?.predicate = self.defaultSearchPredicate
        onSearchCancel()
    }

    func do_searchBarBookmarkButtonClicked(for searchBar: UISearchBar) {
       onSearchCodeScanClicked()
    }

    func do_updateSearchResults(for searchController: UISearchController) {
        //let searchBar = searchController.searchBar
        //if let searchText = searchBar.text {
        //performSearch(searchText) // already done by search bar listener
        //}
    }

}

extension ListFormSearchable where Self: UIViewController {

    // by default open a sesssion to scan
    func showCodeScanController() {
        let controller = BarcodeScannerViewController()

        controller.onDismissCallback = { dismissedController in
            dismissedController.dismiss(animated: true) {
                self.onBarcodeScannerDismiss(controller)
            }
        }
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true) {
            logger.debug("Search with bar code presented")
        }
    }

    private func onBarcodeScannerDismiss(_ controller: BarcodeScannerViewController) {
        logger.debug("Search with bar code dismissed")
        guard let metadata = controller.metadata else { return } // nothing scanned
        guard searchBar.text != metadata else { return } // nothing changed

        if let url = URL(string: metadata) {
            if url.hasAppUserScheme {
                UIApplication.shared.open(url, options: [:]) { _ in
                    logger.debug("Open url \(url) get from qr code")
                }
            } else if url.matchAppAssociatedDomain, let deepLink = DeepLink.from(url) {
                foreground {
                    ApplicationCoordinator.open(deepLink) {_ in
                        logger.debug("Open url \(url) get from qr code")
                    }
                }
            } else {
                barcodeSearch(with: metadata)
            }
        } else {
            barcodeSearch(with: metadata)
        }
    }

    private func barcodeSearch(with metadata: String) {
        searchBar.text = metadata
        foreground {
            self.searchOpenIfOne = true
            self.performSearch(metadata)
        }
    }

}

extension URL {
    /// True if url must open this app through url scheme
    fileprivate var hasAppUserScheme: Bool {
        if let scheme = self.scheme, let urlSchemes = UIApplication.urlSchemes {
            return urlSchemes.contains(scheme)
        }
        return false
    }
    /// True if url must open this app through url scheme
    fileprivate var matchAppAssociatedDomain: Bool {
        if let associatedDomain = UIApplication.associatedDomain {
           return self.host == associatedDomain
        }
        return false
    }
}

// some urls info about app (if necessary could be cached)
extension UIApplication {
    fileprivate static var urlSchemes: [String]? {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: AnyObject]] else {
            return nil
        }
        let result: [String] = urlTypes.compactMap({ $0["CFBundleURLSchemes"] as? [String]}).flatMap({$0})
        return result.isEmpty ? nil : result
    }
    fileprivate static var associatedDomain: String? {
        guard let entitlements = Prephirences.sharedInstance["entitlements"] as? [String: AnyObject] else {
            return nil
        }
        return entitlements["associatedDomain"] as? String
    }
}
