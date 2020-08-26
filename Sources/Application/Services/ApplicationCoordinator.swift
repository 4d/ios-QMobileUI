//
//  ApplicationCoordinator.swift
//  QMobileUI
//
//  Created by phimage on 07/05/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileDataStore
import QMobileDataSync
import QMobileAPI

import XCGLogger
import Prephirences
import SwiftyJSON

open class ApplicationCoordinator: NSObject {}

extension ApplicationCoordinator: ApplicationService {

    static var instance: ApplicationCoordinator = ApplicationCoordinator()
    static var mainCoordinator = MainCoordinator()

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let options = launchOptions,
            /*let userActivtyDictionary = options[.userActivityDictionary] as? [UIApplication.LaunchOptionsKey: Any],
             let userActivityType = userActivtyDictionary[.userActivityType] as? String, userActivityType == NSUserActivityTypeBrowsingWeb */
            let url = options[.url] as? URL,
            let deepLink = DeepLink.from(url) else {
                return
        }
        ApplicationCoordinator.open(deepLink) { presented in
            if presented {
                logger.info("Open \(deepLink) from user activity \(url).")
            } else {
                logger.warning("Failed to open \(deepLink) from user activity \(url)")
            }
        }
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        guard let deepLink = DeepLink.from(url) else {
            return
        }
        ApplicationCoordinator.open(deepLink) { presented in
            if presented {
                logger.info("Open \(deepLink) from url.")
            } else {
                logger.warning("Failed to open \(deepLink) from url \(url)")
            }
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let deepLink = DeepLink.from(url) else {
                return false
        }
        ApplicationCoordinator.open(deepLink) { presented in
            if presented {
                logger.info("Open \(deepLink) from user activity \(url)")
            } else {
                logger.warning("Failed to open \(deepLink) from user activity \(url)")
            }
        }
        return true
    }
}

extension ApplicationCoordinator {
    static func present(_ viewControllerToPresent: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let presenter = UIApplication.topViewController else {
            logger.warning("Failed to present \(viewControllerToPresent). No top controller.")
            completion(false)
            return
        }
        presenter.present(viewControllerToPresent, animated: true) {
            completion(true)
        }
    }

    static func present(_ storyboard: UIStoryboard, completion: @escaping (Bool) -> Void) {
        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present '\(storyboard)'. Cannot instantiate initial form.")
            completion(false)
            return
        }

        present(viewControllerToPresent, completion: completion)
    }

    fileprivate static func storyboardTableName(_ tableName: String) -> String {
        var finalTableName = tableName
        let dataStore = ApplicationDataStore.instance.dataStore // XXX this code will not work if core data not loaede yet...
        _ = dataStore.perform(.foreground, wait: true, blockName: "GetOriginalName:\(tableName)") { context in
            if let tableInfo = context.tableInfo(forOriginalName: tableName) {
                finalTableName = tableInfo.name
            }
        }
        return finalTableName
    }

}

// MARK: - transition

extension ApplicationCoordinator {

    /// Transition 1->N relation from DetailForm
    static func transition<S: DetailsForm & UIViewController, D: ListForm & UIViewController>(from source: S, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        //assert(source.isPresented)
        self.prepare(from: source, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition 1->N relation from ListForm
    static func transition<S: ListForm & UIViewController, D: ListForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        //assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition for N->1 relation from ListForm
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        //assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition to details
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, completion: @escaping () -> Void) {
        //assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition N->1 relation from DetailForm
    static func transition<S: DetailsForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        //assert(source.isPresented)
        self.prepare(from: source, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

}

// MARK: - prepare data

extension ApplicationCoordinator {

    /// Prepare data for 1->N relation from DetailForm
    static func prepare(from source: DetailsForm, to destination: ListForm, relationInfoUI: RelationInfoUI) {
        guard let relationName = relationInfoUI.relationName else {
            logger.error("No relation info to transition between in \(source) to  \(destination)")
            return
        }
        guard let record = source._record else {
            logger.error("Cannot get source record in \(source) to display its relation \(relationName)")
            return
        }
        guard destination.dataSource == nil else {
            logger.info(" data source \(String(describing: destination.dataSource))")
            assertionFailure("data source must not be set yet to be able to inject predicate, if there is change in arch check predicate injection")
            return
        }

        var relationToSeach = relationName
        if let lastIndex = relationName.lastIndex(of: ".") {
            relationToSeach = String(relationName[relationName.index(lastIndex, offsetBy: 1)...]) // CHECK: if more than one path, it will not work?
        }

        guard let inverseRelationInfo = destination.tableInfo?.relationships.first(where: { $0.inverseRelationship?.name == relationToSeach})
            else {
                logger.warning("No information about the inverse of relation \(relationName) in data model to find inverse relation")
                logger.warning("Current table info \(String(describing: destination.tableInfo))")
                return
        }

        let relationOriginalName = destination.tableInfo?.relationshipsByName[relationName]?.originalName ?? relationName // BUG check this value, with . too (why do not take from previsous search?)

        var recordSearch: RecordBase?
        if relationToSeach != relationName { // multilevel, we must find element instead of current record
            if let lastIndex = relationName.lastIndex(of: ".") {
                if let intermediateRecord = record.value(forKeyPath: String(relationName[..<lastIndex])) as? RecordBase {
                    recordSearch = intermediateRecord
                } else {
                    logger.debug("No record to related for relation. no record linked for \(record) with relation \(relationName)")
                }
            }// else must not occurs (asert?)
        } else {
            recordSearch = record.store
        }

        var previousTitle: String?
        if let relationFormat = relationInfoUI.relationFormat,
            !relationFormat.isEmpty,
            let record = recordSearch,
            let tableInfo = recordSearch?.tableInfo,
            let formatter = RecordFormatter(format: relationFormat, tableInfo: tableInfo) {
            previousTitle = formatter.format(record)
        }
        let predicatString = "(\(inverseRelationInfo.name) = %@)"

        guard let recordID = recordSearch?.objectID else {
            logger.warning("No record to check database relation")
            return
        }
        destination.formContext = FormContext(predicate: NSPredicate(format: predicatString, recordID),
                                              actionContext: source.actionContext(), // TODO check action context if deep relation
                                              previousTitle: previousTitle,
                                              relationName: relationOriginalName,
                                              inverseRelationName: inverseRelationInfo.originalName)

        logger.debug("Will display relation \(relationName) of record \(record) using predicat \(predicatString) : \(String(describing: record[relationName]))")
    }

    /// Prepare data for 1->N relation from ListForm
    static func prepare(from source: ListForm, at indexPath: IndexPath, to destination: ListForm, relationInfoUI: RelationInfoUI) {
        guard let entry = source.dataSource?.entry() else { return }
        entry.indexPath = indexPath

        guard let relationName = relationInfoUI.relationName else {
            logger.error("No relation info to transition between in \(source) to  \(destination)")
            return
        }

        // CLEAN: factorize code with DetailForm for relation segue
        guard let record = entry.record as? Record else {
            logger.warning("No record to check database relation")
            return
        }
        let recordID = record.store.objectID

        guard destination.dataSource == nil else {
            logger.info(" data source \(String(describing: destination.dataSource))")
            assertionFailure("data source must not be set yet to be able to inject predicate, if there is change in arch check predicate injection")
            return
        }
        guard let inverseRelationInfo = destination.tableInfo?.relationships.first(where: { $0.inverseRelationship?.name == relationName})
            else {
                logger.warning("No information about the inverse of relation \(relationName) in data model to find inverse relation")
                logger.warning("Current table info \(String(describing: destination.tableInfo))")
                return
        }

        let relationOriginalName = destination.tableInfo?.relationshipsByName[relationName]?.originalName ?? relationName

        var previousTitle: String?
        if let tableInfo = destination.tableInfo,
            let relationFormat = relationInfoUI.relationFormat,
            let formatter = RecordFormatter(format: relationFormat, tableInfo: tableInfo), !relationFormat.isEmpty {
            previousTitle = formatter.format(record)
        }
        let predicatString = "(\(inverseRelationInfo.name) = %@)"
        destination.formContext = FormContext(predicate: NSPredicate(format: predicatString, recordID),
                                              actionContext: source.actionContext(),
                                              previousTitle: previousTitle,
                                              relationName: relationOriginalName,
                                              inverseRelationName: inverseRelationInfo.originalName)

        logger.debug("Will display relation \(relationName) of record \(record) using predicat \(predicatString) : \(String(describing: record[relationName]))")
    }

    /// Prepare data for N->1 relation from ListForm
    static func prepare(from source: ListForm, at indexPath: IndexPath, to destination: DetailsForm, relationInfoUI: RelationInfoUI) {
        guard let entry = source.dataSource?.entry() else { return }
        entry.indexPath = indexPath
        guard let relationName = relationInfoUI.relationName else {
            logger.error("No relation info to transition between in \(source) to  \(destination)")
            return
        }

        guard let record = entry.record as? Record else {
            logger.warning("Cannot get source record in \(source) to display its relation \(relationName)")
            return
        }

        guard let relationRecord = record[relationName] as? RecordBase else {
            logger.warning("Cannot display relation \(relationName) of record \(record)")
            return
        }
        guard let relationDataSource: DataSource = RecordDataSource(record: relationRecord) else {
            logger.warning("Cannot get record attribute to make data source: \(relationRecord)")
            return
        }

        let destinationEntry = DataSourceEntry(dataSource: relationDataSource)
        destinationEntry.indexPath = .zero
        destination.prepare(with: destinationEntry)

        logger.debug("Will display relation \(relationName) of record \(record)")
    }

    /// Prepare data to display detail from ListForm
    static func prepare(from source: ListForm, at indexPath: IndexPath, to destination: DetailsForm) {
        // create a new entry to bind
        guard let entry = source.dataSource?.entry() else { return }
        entry.indexPath = indexPath
        // pass to view controllers and views
        destination.prepare(with: entry)

        // listen to index path change, to scroll table to new selected record
        entry.add(indexPathObserver: source)
    }

    /// Prepare data for N->1 relation from DetailForm
    static func prepare(from source: DetailsForm, to destination: DetailsForm, relationInfoUI: RelationInfoUI) {
        guard let relationName = relationInfoUI.relationName else {
            logger.error("No relation info to transition between in \(source) to  \(destination)")
            return
        }

        guard let record = source._record else {
            logger.warning("Cannot get source record in \(source) to display its relation \(relationName)")
            return
        }
        guard let relationRecord = record[relationName] as? RecordBase else {
            logger.warning("Cannot display relation \(relationName) of record \(record) in \(source). Maybe no one is associated.")
            return
        }
        guard let relationDataSource: DataSource = RecordDataSource(record: relationRecord) else {
            logger.warning("Cannot get record attribute to make data source: \(relationRecord) from \(source)")
            return
        }

        let entry = DataSourceEntry(dataSource: relationDataSource)
        entry.indexPath = .zero
        destination.prepare(with: entry)
        logger.debug("Will display relation \(relationName) of record \(record)")
    }
}

// MARK: open specific data form

extension ApplicationCoordinator {

    public static func open(tableName: String, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))ListForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)

        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            completion(false)
            return
        }

        present(viewControllerToPresent) { presented in
            logger.debug("table '\(tableName)' form presented")
            completion(presented)
        }
    }

    public static func open(tableName: String, primaryKeyValue: Any, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            completion(false)
            return
        }

        let dataStore = ApplicationDataStore.instance.dataStore
        _ = dataStore.perform(.foreground, wait: false, blockName: "Presenting \(tableName) record") { (context) in

            guard let tableInfo = context.tableInfo(forOriginalName: tableName) else {
                logger.warning("Failed to get table info of table \(tableName) to present form")
                completion(false)
                return
            }

            //let predicate = tableInfo.api.predicate(for: primaryKeyValue)
            guard let predicate = tableInfo.primaryKeyPredicate(value: primaryKeyValue) else {
                logger.warning("Failed to request by predicate the \(tableName) with id \(primaryKeyValue) to present table '\(tableName)' form")
                completion(false)
                return
            }

            guard let relationDataSource: DataSource = RecordDataSource(tableInfo: tableInfo, predicate: predicate, dataStore: dataStore) else {
                logger.warning("Cannot get record attribute to make data source: \(primaryKeyValue) when presenting form \(tableName)")
                completion(false)
                return
            }
            let entry = DataSourceEntry(dataSource: relationDataSource)
            entry.indexPath = IndexPath(item: 0, section: 0)

            guard entry.record != nil else {
                logger.warning("Could not find the record \(tableName) \(primaryKeyValue)")
                completion(false)
                return
            }

            foreground {
                viewControllerToPresent.prepare(with: entry)

                present(viewControllerToPresent) { presented in
                    logger.debug("table '\(tableName)' record \(primaryKeyValue) form presented")
                    completion(presented)
                }
            }

        }
    }

    public static func open(tableName: String, primaryKeyValue: Any, relationName: String, completion: @escaping (Bool) -> Void) {
        let dataStore = ApplicationDataStore.instance.dataStore
        _ = dataStore.perform(.foreground, wait: false, blockName: "Presenting \(tableName) record") { (context) in

            guard let tableInfo = context.tableInfo(forOriginalName: tableName) else {
                logger.warning("Failed to get table info of table \(tableName) to present form")
                completion(false)
                return
            }

            //let predicate = tableInfo.api.predicate(for: primaryKeyValue)
            guard let predicate = tableInfo.primaryKeyPredicate(value: primaryKeyValue) else {
                logger.warning("Failed to request by predicate the \(tableName) with id \(primaryKeyValue) to present table '\(tableName)' form")
                completion(false)
                return
            }

            guard let relationDataSource: DataSource = RecordDataSource(tableInfo: tableInfo, predicate: predicate, dataStore: dataStore, context: context, fetchLimit: 1) else {
                logger.warning("Cannot get record attribute to make data source: \(primaryKeyValue) when presenting form \(tableName)")
                completion(false)
                return
            }
            let entry = DataSourceEntry(dataSource: relationDataSource)
            entry.indexPath = .zero
            guard let record = entry.record as? Record else {
                logger.warning("Could not find the record \(tableName) \(primaryKeyValue)")
                completion(false)
                return
            }

            guard let relationShipInfo = tableInfo.relationshipsByName[relationName], let relationTable = relationShipInfo.destinationTable else {
                logger.warning("Unknown \(relationName) for record \(tableName) \(primaryKeyValue)")
                completion(false)
                return
            }

            logger.info("Will display relation \(relationName) of record \(record)")

            foreground {
                let storyboardName = relationShipInfo.isToMany ? "\(relationTable.name)ListForm": "\(relationTable.name)DetailsForm"
                let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
                guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
                    logger.warning("Failed to present form for table '\(tableName)'")
                    completion(false)
                    return
                }

                if relationShipInfo.isToMany {
                    if let destination = viewControllerToPresent.firstController as? ListForm, let inverseRelationInfo = relationShipInfo.inverseRelationship {
                        let predicatString = "(\(inverseRelationInfo.name) = %@)"
                        let relationFormat = relationShipInfo.format
                        var previousTitle: String?
                        if let relationFormat = relationFormat,
                            let formatter = RecordFormatter(format: relationFormat, tableInfo: tableInfo), !relationFormat.isEmpty {
                            previousTitle = formatter.format(record)
                        }

                        destination.formContext = FormContext(predicate: NSPredicate(format: predicatString, record.store.objectID),
                                                              actionContext: entry,
                                                              previousTitle: previousTitle,
                                                              relationName: relationShipInfo.originalName,
                                                              inverseRelationName: inverseRelationInfo.originalName)

                    } else {
                        logger.warning("Failed to transition to relation \(relationName)")
                        completion(false)
                        return
                    }
                } else {
                    if let relationRecord = record[relationName] as? RecordBase, let relationDataSource = RecordDataSource(record: relationRecord) {
                        let relationEntry = DataSourceEntry(dataSource: relationDataSource)
                        relationEntry.indexPath = .zero
                        viewControllerToPresent.prepare(with: relationEntry)
                    } else {
                        logger.warning("Failed to transition to relation \(relationName)")
                        completion(false)
                        return
                    }
                }

                present(viewControllerToPresent) { presented in
                    logger.debug("table '\(String(describing: relationShipInfo.destinationTable?.name))' form presented")
                    completion(presented)
                }
            }

        }
    }

    public static func open(tableName: String, record: Record, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)

        guard let relationDataSource: DataSource = RecordDataSource(record: record.store) else {
            logger.warning("Cannot get record attribute to make data source: \(record) when presenting form \(tableName)")
            completion(false)
            return
        }
        let entry = DataSourceEntry(dataSource: relationDataSource)
        entry.indexPath = .zero

        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            completion(false)
            return
        }
        viewControllerToPresent.prepare(with: entry)

        present(viewControllerToPresent) { presented in
            logger.debug("table '\(tableName)' form presented")
            completion(presented)
        }
    }

    public static func open<S: Storyboardable>(storyboardable: S.Type, completion: @escaping (Bool) -> Void) {
        present(storyboardable.storyboard) { presented in
            logger.debug("present '\(storyboardable)'")
            completion(presented)
        }
    }

    public static func open(_ deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        mainCoordinator.follow(deepLink: deepLink) { managed in
            if managed {
                completion(true)
            } else {
                switch deepLink {
                case .login:
                    self.open(storyboardable: LoginForm.self, completion: completion)
                case .main:
                    self.open(storyboardable: Main.self, completion: completion)
                case .settings:
                    self.open(storyboardable: SettingsForm.self, completion: completion)
                case .mainNavigation:
                    self.open(storyboardable: MainNavigation.self, completion: completion)
                case .table(let tableName):
                    self.open(tableName: tableName, completion: completion)
                case .record(let tableName, let primaryKeyValue):
                    self.open(tableName: tableName, primaryKeyValue: primaryKeyValue, completion: completion)
                case .relation(let tableName, let primaryKeyValue, let relationName):
                    self.open(tableName: tableName, primaryKeyValue: primaryKeyValue, relationName: relationName, completion: completion)
                }
            }
        }
    }

}

struct MainCoordinator {

    var mainNavigationCoordinator = MainNavigationCoordinator()
    var loginCoordinator = LoginCoordinator()

    var form: Main? {
        return UIApplication.topViewController?.hierarchy?.first(where: { $0 is Main }) as? Main
        //  self.form = Main.self.instantiateInitialViewController() as? Main // if we force build by coordinator
    }

    func follow(deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        switch deepLink {
        case .login:
            loginCoordinator.follow(deepLink: deepLink, completion: completion)
        default:
            mainNavigationCoordinator.follow(deepLink: deepLink, completion: completion)
        }
        // #118062 Manage if logged or not
    }
}

struct LoginCoordinator {

    var form: LoginForm? {
        if let topVC = UIApplication.topViewController as? LoginForm {
            return topVC
        }
        return UIApplication.topViewController?.hierarchy?.first(where: { $0 is LoginForm }) as? LoginForm
    }

    func follow(deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        if let form = form {
            form.login(deepLink)
        }
    }
}

struct MainNavigationCoordinator {

    var form: MainNavigationForm? {
        return UIApplication.topViewController?.hierarchy?.first(where: { $0 is MainNavigationForm }) as? MainNavigationForm
        //  self.form = MainNavigation.self.instantiateInitialViewController() as? MainNavigationForm // if we force build by coordinator
    }

    func follow(deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        switch deepLink {
        case .settings:
            if let foundForm = self.form?.childrenForms.first(where: { $0.firstController is SettingsForm }) {
                self.form?.presentChildForm(foundForm)
                completion(true) // managed
                return
            }
            completion(false)
        case .table(let tableName):
            if let foundForm = self.form?.childrenForms.first(where: { ($0.firstController as? ListForm)?.tableName == tableName }) {
                self.form?.presentChildForm(foundForm)
                completion(true) // managed
                return
            }
            completion(false)
        case .record(let tableName, _):
            if self.form?.childrenForms.first(where: { ($0.firstController as? ListForm)?.tableName == tableName }) != nil { // present list form parent only if in tabs, otherwise just open as modal
                if let tableParentLink = deepLink.parent {
                    ApplicationCoordinator.open(tableParentLink) { _ in
                        completion(false)
                    }
                    return
                }
            }
            completion(false)
        case .relation:
            if let recordParentLink = deepLink.parent { // for relation always try to open parent record
                ApplicationCoordinator.open(recordParentLink) { _ in
                    completion(false)
                }
                return
            }
            completion(false)
        default:
            completion(false)
        }
    }

}
