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
public protocol ListForm: DataSourceDelegate, DataSourceSortable, IndexPathObserver, ActionContextProvider, FixedForm, Storyboardable, DeepLinkable, TableOwner {

    /// The table name displayed by this form.
    var tableName: String { get }
    /// The data source.
    var dataSource: DataSource? { get }
    /// A context that could change the for behaviour.
    var formContext: FormContext? { get set }

    var inDataSync: Bool { get set }
    var isViewVisible: Bool { get set }
    var isScrolling: Bool { get set }

}

public protocol FixedForm: NSObjectProtocol, Form {

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
        return .table(self.tableInfo?.originalName ?? self.tableName)
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

    /// Get an action context for the list form ie. the table (and maybe its relation)
    public func actionContext() -> ActionContext? {
        if let formContext = self.formContext {
            return DataSourceParentEntry(actionContext: self.dataSource, formContext: formContext)
        } else {
            return self.dataSource
        }
    }

    /// Get an action context for a specific row ie a record/entity
    public func actionContext(forRowAt indexPath: IndexPath) -> ActionContext? {
        guard let context = self.dataSource?.entry() else { return nil }
        context.indexPath = indexPath
        if let formContext = self.formContext {
            return DataSourceParentEntry(actionContext: context, formContext: formContext)
        } else {
            return context
        }
    }

}

extension UIViewController {

    func fixNavigationBarColorFromAsset() {
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
        if navigationBar.titleTextAttributes?[.foregroundColor] == nil {
            navigationBar.titleTextAttributes?[.foregroundColor] = namedColor
        } else if let oldColor = navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor, oldColor.rgba.alpha < 0.5 {
            navigationBar.titleTextAttributes?[.foregroundColor] = namedColor
        }

        applyScrollEdgeAppareance()
    }

}

extension FixedForm where Self: UIViewController {

    func fixNavigationBarColor() {
        fixNavigationBarLargeTitlePosition() // redmine #110851: try to show large title always and make status bar color active when starting
        fixNavigationBarColorFromAsset()
    }

    fileprivate func fixNavigationBarLargeTitlePosition() {
        self.scrollView?.setContentOffset(CGPoint(x: 0, y: -10), animated: false)
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

extension ListForm where Self: UIViewController {

    var dataSyncEventObject: Any? {
        return nil // ApplicationDataSync.dataSync{
    }
    var dataSyncEvents: [Notification.Name] {
        // let names: [Notification.Name] = [.dataSyncForTableBegin, .dataSyncForTableSuccess, .dataSyncForTableFailed]
        let names: [Notification.Name] = [.dataSyncWillBegin, .dataSyncSuccess, .dataSyncFailed]
        return names
    }
    func installObservers(_ selector: Selector) {
        removeObservers()
        let object: Any? = dataSyncEventObject
        let center: NotificationCenter = .default
        for name in dataSyncEvents {
            center.addObserver(self, selector: selector, name: name, object: object)
        }
    }
    func removeObservers() {
        let object: Any? = dataSyncEventObject
        let center: NotificationCenter = .default
        for name in dataSyncEvents {
            center.removeObserver(self, name: name, object: object)
        }
    }
    func dataSyncEvent(_ notification: Notification) {
        /*guard let table = notification.userInfo?["table"] as? Table, self.table == table else {
            return
        }*/
        switch notification.name {
        case .dataSyncForTableBegin, .dataSyncWillBegin:
            inDataSync = true
        case .dataSyncForTableSuccess, .dataSyncForTableFailed, .dataSyncSuccess, .dataSyncFailed:
            inDataSync = false
        default:
            return
        }
    }
    func updateProgressBar() { // CLEAN Change with combine of 3 bool events?
        if inDataSync && isViewVisible && !isScrolling {
            foreground {
                // if UIApplication.topViewController?.firstController == self {
                LinearProgressBar.removeAllProgressBars(self.view)
                LinearProgressBar.showProgressBar(self.view) // DO not show animated bar in not visible controller, 100%cpu
                // }
            }
        } else {
            foreground {
                LinearProgressBar.removeAllProgressBars(self.view)
            }
        }
    }
}
