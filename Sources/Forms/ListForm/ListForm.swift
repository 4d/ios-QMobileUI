//
//  ListForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

/// Context of a form, to filter or have information on parent controller
public struct FormContext {

    var predicate: NSPredicate?
    var actionContext: ActionContext?
    var previousTitle: String?
    var relationName: String?
    var inverseRelationName: String?

}

/// A List form display a list of table data
public protocol ListForm: DataSourceDelegate, DataSourceSortable, IndexPathObserver, ActionContextProvider, Form, Storyboardable, DeepLinkable {

    /// The table name displayed by this form.
    var tableName: String { get }
    /// The data source.
    var dataSource: DataSource? { get }
    /// A context that could change the for behaviour.
    var formContext: FormContext? { get set }

    /// A parent controller. (used to fix issue with more view controller).
    var originalParent: UIViewController? { get set }
    /// A scroll view used to fix navigation bar scrolling position..
    var scrollView: UIScrollView? { get }
}

extension ListForm {

    public var deepLink: DeepLink? {
        /*if context = self.formContext {
            // return .relation(T##String, T##Any, T##String) // TODO manage by relation deeplink
        }*/
        return .table(self.tableName)
    }

    func configureListFormView(_ view: UIView, _ record: AnyObject, _ indexPath: IndexPath) {
        // Give view information about records, let binding fill the UI components
        let entry = self.dataSource?.entry()
        entry?.indexPath = indexPath
        view.table = entry
    }

    var defaultTableName: String {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)

        let name = className.camelFirst
        if NSClassFromString(name) != nil { // check entity
            return name
        }
        logger.error("Looking for class \(className) to determine the type of records to load. But no class with this name found in the project. Check your data model.")
        abstractMethod(className: className)
    }

    public var firstRecord: Record? {
        return dataSource?.record(at: IndexPath.firstRow)
    }

    public var lastRecord: Record? {
        guard let index = dataSource?.lastIndexPath else {
            return nil
        }
        return dataSource?.record(at: index)
    }

}

// MARK: - ActionContextProvider

extension ListForm {

    public func actionContext() -> ActionContext? {
        if let formContext = self.formContext {
            return DataSourceParentEntry(actionContext: self.dataSource, formContext: formContext)
        } else {
            return self.dataSource
        }
    }

}

extension ListForm where Self: UIViewController {

    func fixNavigationBarColor() {
        fixNavigationBarLargeTitlePosition() // redmine #110851: try to show large title always and make status bar color active when starting
        fixNavigationBarColorFromAsset()
    }

    fileprivate func fixNavigationBarLargeTitlePosition() {
        self.scrollView?.setContentOffset(CGPoint(x: 0, y: -10), animated: false)
    }

    fileprivate func fixNavigationBarColorFromAsset() {
        guard let navigationBar = self.navigationController?.navigationBar else {
            return }
        guard let namedColor = UIColor(named: "ForegroundColor") else { return } // cannot fix
        var attributes = navigationBar.titleTextAttributes ?? [:]
        if let oldColor = attributes[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {

            /// Apple issue with navigation bar color which use asset color as foreground color
            /// If we detect the issue ie. alpha color less than 0.5, we apply your "ForegroundColor" color
            attributes[.foregroundColor] = namedColor
            navigationBar.titleTextAttributes = attributes
        }
        if navigationBar.largeTitleTextAttributes == nil {
            navigationBar.largeTitleTextAttributes = navigationBar.titleTextAttributes
        } else {
            if navigationBar.largeTitleTextAttributes?[.foregroundColor] == nil {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            } else if let oldColor = navigationBar.largeTitleTextAttributes?[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {
                navigationBar.largeTitleTextAttributes?[.foregroundColor] = namedColor
            }
        }

        applyScrollEdgeAppareance()
    }

    func manageMoreNavigationControllerStyle(_ parent: UIViewController?) {
        if parent == nil {
            self.originalParent = self.parent
        } else if let moreNavigationController = parent as? UINavigationController, moreNavigationController.isMoreNavigationController {
            if let navigationController = self.originalParent  as? UINavigationController {
                moreNavigationController.navigationBar.copyAppearance(from: navigationController.navigationBar)
            }
        }
    }

}

public protocol ListFormSearchable: ListForm/*, DataSourceSearchable*/ {
    var searchBar: UISearchBar! { get set }
    /// Add search bar in place of navigation bar title
    var searchableAsTitle: Bool { get }
    /// Keep search bar if scrolling (only if searchableAsTitle = false)
    var searchableWhenScrolling: Bool { get }
    /// Hide navigation bar when searching (only if searchableAsTitle = false)
    var searchableHideNavigation: Bool { get }
    /// Activate search with code scanner
    var searchableUsingCodeScanner: Bool { get }

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
        if let subview = searchBar?.subviews.first {
            let textFields = subview.allSubviews.compactMap({$0 as? UITextField })
            if let searchTextField = textFields.first {
                //if !searchableAsTitle {
                    if let navigationBarColor = self.navigationController?.navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor {
                        searchTextField.textColor = navigationBarColor
                    }
                //}
                searchTextField.tintColor = searchTextField.textColor // the |
            }
        }
        searchBar?.delegate = self

        if isSearchBarMustBeHidden {
            searchBar?.isHidden = true
        }

        if self.searchableUsingCodeScanner {
            self.searchBar?.showsBookmarkButton = true
            self.searchBar?.setImage(UIImage(systemName: "qrcode"), for: .bookmark, state: .normal)
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
        let controller = BarcodeScannerSearchBarViewController()
        controller.searchBar = self.searchBar
        controller.onDismissCallback = { dismissedController in
            dismissedController.dismiss(animated: true) {
                logger.debug("Search with bar code dismissed")
            }
        }
        self.present(controller, animated: true) {
            logger.debug("Search with bar code presented")
        }
    }

}

public class BarcodeScannerSearchBarViewController: BarcodeScannerViewController {

    public var searchBar: UISearchBar!

    override open func onMetaDataOutput(_ metadata: String) {
        searchBar.text = metadata
    }

}

// MARK: navigation menu controller
/*
let useImage = false
let useMenuTitle = true

@available(iOS 13.0, *)
extension UIViewController: UIContextMenuInteractionDelegate {

    public var displayableHierachy: [UIViewController]? {
        let presentationStyle = self.modalPresentationStyle
        if presentationStyle == .automatic || presentationStyle == .pageSheet {
            if let parent = self.parent {
                return [parent] + (parent.hierarchy ?? [])
            }
            if let presentingViewController = self.presentingViewController {
                return [presentingViewController] + (presentingViewController.hierarchy ?? [])
            }
        }
        return nil
    }

    public func contextMenuInteractionWillPresent(_ interaction: UIContextMenuInteraction) {}

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let hierarchy: [UIViewController] = self.displayableHierachy else {  return nil }

        let actionImage: UIImage? = useImage ? UIImage(systemName: "arrow.left.to.line"): nil
        let menuTitle = useMenuTitle ? "Go Back": ""

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            var children: [UIMenuElement] = []
            for vcInHierarchy in hierarchy {
                let firstController = vcInHierarchy.firstController
                let title = firstController.navigationItem.title
                if firstController == self {
                    // ignore current level
                } else if vcInHierarchy == firstController { // last one main?, ie. stop to last one...
                    let action = UIAction(title: vcInHierarchy.firstSelectedController.navigationItem.title ?? "Dismiss all", image: actionImage) { _ in
                        vcInHierarchy.firstSelectedController.dismiss(animated: true)
                    }
                    children.append(action)

                    // If want to add tab bar controller level
                    /*if let tabBarController = vc as? UITabBarController {
                     // allow to show all ?
                     if let tabs = tabBarController.viewControllers {
                     var children0: [UIMenuElement] = []
                     for tab in tabs {0
                     let form = tab.firstController
                     let title = form.navigationItem.title
                     if !(hierarchy.map { $0.firstController }.contains(form)) {

                     let action = UIAction(title: title ?? "\(form)", image: tab.tabBarItem?.image ??   form.tabBarItem?.image ?? UIImage(systemName: "square")) { action in
                     tabBarController.selectedViewController?.dismiss(animated: true, completion: {

                     tabBarController.selectedViewController = tab
                     })
                     }
                     // children0.append(action)
                     children.append(action)
                     }
                     }

                     //  let menu0 =   UIMenu(title: "tab", children: children0)

                     //  children.append(menu0)
                     }
                     }*/
                } else {
                    let action = UIAction(title: title ?? "\(firstController)", image: actionImage) { _ in
                        firstController.dismiss(animated: true)
                    }
                    children.append(action)
                }
            }
            return UIMenu(title: menuTitle, children: children)
        }
    }

}
*/
