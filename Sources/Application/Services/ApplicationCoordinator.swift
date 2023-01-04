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
import SwiftMessages

open class ApplicationCoordinator: NSObject {}

extension ApplicationCoordinator: ApplicationService {

    static var instance: ApplicationCoordinator = ApplicationCoordinator()
    static var mainCoordinator = MainCoordinator()

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // _ = UIViewController.enableCoordinatorSegues
        guard let options = launchOptions,
            /*let userActivtyDictionary = options[.userActivityDictionary] as? [UIApplication.LaunchOptionsKey: Any],
             let userActivityType = userActivtyDictionary[.userActivityType] as? String, userActivityType == NSUserActivityTypeBrowsingWeb */
            let url = options[.url] as? URL,
            let deepLink = DeepLink.from(url) else {
                return
        }
        DispatchQueue.main.async {
            ApplicationCoordinator.open(deepLink) { presented in
                if presented {
                    logger.info("Open \(deepLink) from launchOptions \(url).")
                } else {
                    logger.warning("Failed to open \(deepLink) from launchOptions \(url)")
                }
            }
        }
    }

    public static func manageConnectionOptions(_ connectionOptions: UIScene.ConnectionOptions) {
        // if scene launchOptions could be nil
        guard let url = connectionOptions.urlContexts.first?.url ?? connectionOptions.userActivities.first(where: { $0.webpageURL != nil })?.webpageURL, let deepLink = DeepLink.from(url) else {
            return
        }
        DispatchQueue.main.async {
            ApplicationCoordinator.open(deepLink) { presented in
                if presented {
                    logger.info("Open \(deepLink) from scene connection options \(url).")
                } else {
                    logger.warning("Failed to open \(deepLink) from scene connection options \(url)")
                }
            }
        }
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        guard let deepLink = DeepLink.from(url) else {
            return
        }
        DispatchQueue.main.async {
            ApplicationCoordinator.open(deepLink) { presented in
                if presented {
                    logger.info("Open \(deepLink) from url.")
                } else {
                    logger.warning("Failed to open \(deepLink) from url \(url)")
                }
            }
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let deepLink = DeepLink.from(url) else {
                return false
        }
        DispatchQueue.main.async {
            ApplicationCoordinator.open(deepLink) { presented in
                if presented {
                    logger.info("Open \(deepLink) from user activity \(url)")
                } else {
                    logger.warning("Failed to open \(deepLink) from user activity \(url)")
                }
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
        // assert(source.isPresented)
        self.prepare(from: source, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition 1->N relation from ListForm
    static func transition<S: ListForm & UIViewController, D: ListForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        // assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition for N->1 relation from ListForm
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        // assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition to details
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, completion: @escaping () -> Void) {
        // assert(source.isPresented)
        self.prepare(from: source, at: indexPath, to: destination)
        source.present(destination, animated: true, completion: completion)
    }

    /// Transition N->1 relation from DetailForm
    static func transition<S: DetailsForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, to destination: D, relationInfoUI: RelationInfoUI, completion: @escaping () -> Void) {
        // assert(source.isPresented)
        self.prepare(from: source, to: destination, relationInfoUI: relationInfoUI)
        source.present(destination, animated: true, completion: completion)
    }

}

// MARK: - prepare data

extension ApplicationCoordinator {

    fileprivate static func getRelationInfos(_ firstTableInfo: DataStoreTableInfo?, _ relationName: String) -> [DataStoreRelationInfo] {
        var tableInfo = firstTableInfo
        var relationsInfo: [DataStoreRelationInfo] = []
        let relationsToSearch = relationName.split(separator: ".").reversed()
        for relationToSearch in relationsToSearch {
            if let inverseRelationInfo = tableInfo?.relationships.first(where: { $0.inverseRelationship?.name == String(relationToSearch) }) {

                relationsInfo.append(inverseRelationInfo)
                tableInfo = inverseRelationInfo.destinationTable
            } else {
                logger.warning("No information about the inverse of relation \(relationName) in data model to find inverse relation: \(relationToSearch)")
                // return
            }
        }
        return relationsInfo
    }

    fileprivate static func prepare(from actionContextProvider: ActionContextProvider, to destination: ListForm, relationInfoUI: RelationInfoUI, record: Record) {
        guard destination.dataSource == nil else {
            logger.info("data source \(String(describing: destination.dataSource)), must not be filled yet")
            assertionFailure("data source must not be set yet to be able to inject predicate, if there is change in arch check predicate injection")
            return
        }
        guard let relationName = relationInfoUI.relationName else {
            logger.error("No relation info to transition between in \(actionContextProvider) to  \(destination)")
            return
        }
        let relationsInfo = getRelationInfos(destination.tableInfo, relationName)

        let relationOriginalName = relationsInfo.reversed().compactMap({$0.inverseRelationship?.originalName}).joined(separator: ".")
        let inverseRelationName = relationsInfo.map({$0.originalName}).joined(separator: ".")

        var previousTitle: String?
        if let relationFormat = relationInfoUI.relationFormat,
           !relationFormat.isEmpty,
           let formatter = RecordFormatter(format: relationFormat, tableInfo: record.store.tableInfo) {
            previousTitle = formatter.format(record)
        }

        var predicatString: String = ""
        switch relationsInfo.count {
        case 0:
            logger.warning("No relation info found in database for \(relationName) ")
            assertionFailure("No relation info provided")
        case 1:
            predicatString = "\(relationsInfo.map({ $0.name }).joined(separator: ".")) = %@" // clean: could take first and remove join
        case 2:
            predicatString = "ANY \(relationsInfo.map({ $0.name }).joined(separator: ".")) = %@"
        default:
            subquery(relationsInfo: relationsInfo.reversed(), predicatString: &predicatString)
        }

        let predicate = NSPredicate(format: predicatString, record.store.objectID)

        destination.formContext = FormContext(predicate: predicate,
                                              actionContext: actionContextProvider.actionContext(),
                                              previousTitle: previousTitle,
                                              relationName: relationOriginalName,
                                              inverseRelationName: inverseRelationName)

        logger.debug("Will display relation \(relationName) of record \(record) using predicat \(predicatString) : \(String(describing: record[relationName]))")
    }

    /// Produce imbricated relation information
    /// ex: SUBQUERY(inverseRight, $x, SUBQUERY($x.inverseSame, $y, $y.left = %@).@count > 0).@count > 0
    static func subquery(relationsInfo: [DataStoreRelationInfo], predicatString: inout String, varName: String = "") {
        var copy = relationsInfo
        if let relationInfo = copy.popLast() {
            if copy.isEmpty { // we are the last query
                predicatString += "ANY $\(varName).\(relationInfo.name) = %@"
            } else {
                predicatString += "SUBQUERY("
                if !varName.isEmpty {
                    predicatString += "$\(varName)."
                }
                predicatString += "\(relationInfo.name)"
                let newVarName = incrementName(varName)
                predicatString += ", $\(newVarName), "
                subquery(relationsInfo: copy, predicatString: &predicatString, varName: newVarName)
                predicatString += ").@count > 0"
            }
        }
    }

    /// Recursive function that increments a name
    fileprivate static func incrementName(_ name: String) -> String { // move to String ext?
        var previousName = name
        if let lastScalar = previousName.unicodeScalars.last {
            let lastChar = previousName.remove(at: previousName.index(before: previousName.endIndex))
            if lastChar == "z" {
                let newName = incrementName(previousName) + "a"
                return newName
            } else {
                let incrementedChar = String(Character(Unicode.Scalar(lastScalar.value + 1) ?? "a"))
                return previousName + incrementedChar
            }
        } else {
            return "a"
        }
    }

    /// Prepare data for 1->N relation from `DetailForm`
    static func prepare(from source: DetailsForm, to destination: ListForm, relationInfoUI: RelationInfoUI) {
        guard let record = source._record else {
            logger.error("Cannot get source record in \(source) to display its relation \(String(describing: relationInfoUI.relationName))")
            return
        }
        prepare(from: source, to: destination, relationInfoUI: relationInfoUI, record: record)
    }

    /// Prepare data for 1->N relation from `ListForm`
    static func prepare(from source: ListForm, at indexPath: IndexPath, to destination: ListForm, relationInfoUI: RelationInfoUI) {
        guard let entry = source.dataSource?.entry() else { return }
        entry.indexPath = indexPath
        guard let record = entry.record as? Record else {
            logger.warning("No record to check database relation")
            return
        }
        prepare(from: source, to: destination, relationInfoUI: relationInfoUI, record: record)
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

struct StoryboardFactory {

    static func storyboard(for name: String, bundle: Bundle = .main) -> UIStoryboard? {
        guard bundle.url(forResource: name, withExtension: "storyboardc") != nil else {
            return nil // prevent crash by not trying to init not existing storyboard
        }
        return UIStoryboard(name: name, bundle: bundle)
    }

}

// MARK: open specific data form

extension ApplicationCoordinator {

    public static func open(tableName: String, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))ListForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = StoryboardFactory.storyboard(for: storyboardName)

        guard let viewControllerToPresent = storyboard?.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            completion(false)
            return
        }

        present(viewControllerToPresent) { presented in
            logger.debug("table '\(tableName)' form presented")
            completion(presented)
        }
    }

    fileprivate static func checkRecord(tableName: String, primaryKeyValue: Any, entry: DataSourceEntry, relationName: String? = nil, context: DataStoreContext, completion: @escaping (Bool) -> Void) -> Bool {
        // If no record, try to sync it
        guard entry.record == nil else {
            logger.verbose("Record found to display it or its relation \(String(describing: entry.record))")
            return true // all is ok
        }
        // try to download it
        SwiftMessages.loading()
        let dataSyncInstance = ApplicationDataSync.instance.dataSync
        _ = dataSyncInstance.sync(operation: .record(tableName, primaryKeyValue), in: context.type) { recordResult in
            logger.debug("Record \(tableName)(\(primaryKeyValue)) synchronised after request to display it: \(recordResult)")

            switch recordResult {
            case .success:
                // retry
                foreground {
                    let newCompletion: (Bool) -> Void = { value in
                        completion(value)
                        DispatchQueue.userInitiated.async {
                            _ = dataSync { _ in } // do full sync too
                        }
                    }
                    if let relationName = relationName {
                        open(tableName: tableName, primaryKeyValue: primaryKeyValue, relationName: relationName, completion: newCompletion)
                    } else {
                        open(tableName: tableName, primaryKeyValue: primaryKeyValue, completion: newCompletion)
                    }
                }
            case .failure(let error):
                logger.warning("Could not find the record \(tableName)(\(primaryKeyValue)) on server: \(error)")
                completion(false)
            }
            DispatchQueue.main.after(1) {
                SwiftMessages.hide()
            }
        }
        return false
    }

    public static func open(tableName: String, primaryKeyValue: Any, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data

        let storyboard = StoryboardFactory.storyboard(for: storyboardName)
        guard let viewControllerToPresent = storyboard?.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            completion(false)
            return
        }

        let dataStore = ApplicationDataStore.instance.dataStore
        let ready = dataStore.perform(.foreground, wait: false, blockName: "Presenting \(tableName) record") { (context) in

            guard let tableInfo = context.tableInfo(forOriginalName: tableName) ?? context.tableInfo(for: tableName) else {
                logger.warning("Failed to get table info of table \(tableName) to present form")
                completion(false)
                return
            }

            // let predicate = tableInfo.api.predicate(for: primaryKeyValue)
            guard let predicate = tableInfo.primaryKeyPredicate(value: primaryKeyValue) else {
                logger.warning("Failed to request by predicate the \(tableName) with id \(primaryKeyValue) to present table '\(tableName)' form")
                completion(false)
                return
            }

            guard let recordDataSource: DataSource = RecordDataSource(tableInfo: tableInfo, predicate: predicate, dataStore: dataStore) else {
                logger.warning("Cannot get record attribute to make data source: \(primaryKeyValue) when presenting form \(tableName)")
                completion(false)
                return
            }
            let entry = DataSourceEntry(dataSource: recordDataSource)
            entry.indexPath = .zero

            guard checkRecord(tableName: tableName, primaryKeyValue: primaryKeyValue, entry: entry, context: context, completion: completion) else {
                logger.warning("Could not find the record \(tableName) \(primaryKeyValue)")
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
        if !ready {
            logger.debug("Could not open \(tableName) \(primaryKeyValue), data store not ready, reschedule it")
            DispatchQueue.main.after(3) {
                open(tableName: tableName, primaryKeyValue: primaryKeyValue, completion: completion)
            }
        }
    }

    public static func open(tableName: String, primaryKeyValue: Any, relationName: String, completion: @escaping (Bool) -> Void) { // swiftlint:disable:this function_body_length
        let dataStore = ApplicationDataStore.instance.dataStore
        let ready = dataStore.perform(.foreground, wait: false, blockName: "Presenting \(tableName) record") { (context) in

            guard let tableInfo = context.tableInfo(forOriginalName: tableName) ?? context.tableInfo(for: tableName) else {
                logger.warning("Failed to get table info of table \(tableName) to present form")
                completion(false)
                return
            }

            // let predicate = tableInfo.api.predicate(for: primaryKeyValue)
            guard let predicate = tableInfo.primaryKeyPredicate(value: primaryKeyValue) else {
                logger.warning("Failed to request by predicate the \(tableName) with id \(primaryKeyValue) to present table '\(tableName)' form")
                completion(false)
                return
            }

            guard let recordDataSource: DataSource = RecordDataSource(tableInfo: tableInfo, predicate: predicate, dataStore: dataStore, context: context, fetchLimit: 1) else {
                logger.warning("Cannot get record attribute to make data source: \(primaryKeyValue) when presenting form \(tableName)")
                completion(false)
                return
            }
            let entry = DataSourceEntry(dataSource: recordDataSource)
            entry.indexPath = .zero

            guard checkRecord(tableName: tableName, primaryKeyValue: primaryKeyValue, entry: entry, relationName: relationName, context: context, completion: completion) else {
                logger.warning("Could not find the record \(tableName) \(primaryKeyValue)")
                return
            }

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
                let storyboard = StoryboardFactory.storyboard(for: storyboardName)
                guard let viewControllerToPresent = storyboard?.instantiateInitialViewController() else {
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
        if !ready {
            logger.debug("Could not open \(tableName) \(primaryKeyValue) relation \(relationName), data store not ready, reschedule it")
            DispatchQueue.main.after(3) {
                open(tableName: tableName, primaryKeyValue: primaryKeyValue, relationName: relationName, completion: completion)
            }
        }
    }

    public static func open(tableName: String, record: Record, completion: @escaping (Bool) -> Void) {
        let storyboardName = "\(storyboardTableName(tableName))DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = StoryboardFactory.storyboard(for: storyboardName)

        guard let relationDataSource: DataSource = RecordDataSource(record: record.store) else {
            logger.warning("Cannot get record attribute to make data source: \(record) when presenting form \(tableName)")
            completion(false)
            return
        }
        let entry = DataSourceEntry(dataSource: relationDataSource)
        entry.indexPath = .zero

        guard let viewControllerToPresent = storyboard?.instantiateInitialViewController() else {
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
        self.open(deepLink, recursive: false, completion: completion) // here to fix weird compilation issue we use two method, instead of one with default value
    }

    public static func open(_ deepLink: DeepLink, recursive: Bool, completion: @escaping (Bool) -> Void) {
        if let deepLinkable = UIApplication.topViewController?.firstController as? DeepLinkable, deepLinkable.deepLink == deepLink {
            logger.log(recursive ? .debug: .info, "Do not open \(deepLink) because already open on top")
            deepLinkable.manage(deepLink: deepLink)
            completion(false)
            return
        }
        mainCoordinator.follow(deepLink: deepLink) { managed in
            if managed {
                completion(true)
            } else {
                foreground { // post pone to let other transition be done in main thread
                    switch deepLink {
                    case .login:
                        self.open(storyboardable: LoginForm.self, completion: completion)
                    case .main:
                        self.open(storyboardable: Main.self, completion: completion)
                    case .settings:
                        self.open(storyboardable: SettingsForm.self, completion: completion)
                    case .navigation:
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

    static func logout() {
        guard Prephirences.Auth.Login.form else {
            return
        }
        mainCoordinator.logout()
        // TODO:  code to be able to logout from anywhere
    }

}

class MainCoordinator {

    var mainNavigationCoordinator = MainNavigationCoordinator()
    var loginCoordinator = LoginCoordinator()

    var form: Main? {
        return UIApplication.topViewController as? Main
    }

    func follow(deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        if self.form != nil {
            // postpone if too soon
            DispatchQueue.main.after(1) {
                self.follow(deepLink: deepLink, completion: completion)
            }
            return
        }
        switch deepLink {
        case .login:
            loginCoordinator.follow(deepLink: deepLink, completion: completion)
        default:
            if APIManager.isSignIn || !ApplicationAuthenticate.hasLogin {
                mainNavigationCoordinator.follow(deepLink: deepLink, completion: completion)
            } else { // #118062 Manage if logged or not
                loginCoordinator.afterLogin(deepLink: deepLink, completion: completion)
            }
        }
    }

    func logout() {
        foreground {
            guard let form = UIApplication.topViewController else {
                logger.warning("Failed to find UI root to logout")
                return
            }
            ApplicationAuthenticate.instance.logoutUI(self, form)
        }
    }
}

class LoginCoordinator {
    var apiManagerObservers: [NSObjectProtocol] = []

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

    func afterLogin(deepLink: DeepLink, completion: @escaping (Bool) -> Void) {
        let loginObserver = APIManager.observe(APIManager.loginSuccess) { _ in
            logger.debug("After loggin try to open deep link")
            self.stopMonitoringAPIManager()
            foreground {
                ApplicationCoordinator.open(deepLink, completion: completion)
            }
        }
        apiManagerObservers += [loginObserver]
    }

    fileprivate func stopMonitoringAPIManager() {
        for observer in apiManagerObservers {
            APIManager.unobserve(observer)
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
                self.form?.presentChildForm(foundForm) {
                    completion(true) // managed
                }
                return
            }
            completion(false)
        case .table(let tableName):
            if let foundForm = self.form?.childrenForms.first(where: { ($0.firstController as? ListForm)?.tableName == tableName }) {
                self.form?.presentChildForm(foundForm) {
                    completion(true) // managed
                }
                return
            }
            completion(false)
        case .record(let tableName, _):
            if self.form?.childrenForms.first(where: { ($0.firstController as? ListForm)?.tableName == tableName }) != nil { // present list form parent only if in tabs, otherwise just open as modal
                if let tableParentLink = deepLink.parent {
                    ApplicationCoordinator.open(tableParentLink, recursive: true) { _ in
                        completion(false)
                    }
                    return
                }
            }
            completion(false)
        case .relation:
            if let recordParentLink = deepLink.parent { // for relation always try to open parent record
                ApplicationCoordinator.open(recordParentLink, recursive: true) { _ in
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
/*
private var segueBoxRef = "segueBoxRef"

fileprivate extension UIViewController {
    static let enableCoordinatorSegues: Void = {
        swizzle(UIViewController.self, #selector(prepare(for:sender:)), #selector(swizzled_prepare(for:sender:)))
    }()
    @objc func swizzled_prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? SegueBox {
            sender.configure(segue.destination)
        }
        swizzled_prepare(for: segue, sender: sender)
    }

    var segueBox: SegueBox? {
        get { return objc_getAssociatedObject(self, &segueBoxRef) as? SegueBox }
        set { objc_setAssociatedObject(self, &segueBoxRef, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private class SegueBox {
    let configure: (UIViewController) -> Void

    init(configure: @escaping (UIViewController) -> Void) {
        self.configure = configure
    }
}

private func swizzle(_ `class`: AnyClass, _ originalSelector: Selector, _ swizzledSelector: Selector) {
    let originalMethod = class_getInstanceMethod(`class`, originalSelector)!
    let swizzledMethod = class_getInstanceMethod(`class`, swizzledSelector)!

    let didAdd = class_addMethod(
        `class`, originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    )

    if didAdd {
        class_replaceMethod(
            `class`, swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}*/ // swiftlint:disable:this file_length // TODO cut this coordiantor file
