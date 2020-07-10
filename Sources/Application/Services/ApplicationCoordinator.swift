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

open class ApplicationCoordinator: NSObject {

    public enum State {
        case main // onboarding?
        case mainNavigation
        case login
        case settings
        case table(String)
        case record(String, Any)
        case relation(String, Any, String)

        // Return state from push notif informaton for instance
        static func from(_ userInfo: [AnyHashable: Any]) -> State? {
            if let table = userInfo["table"] as? String {
                if let record = userInfo["record"] {
                    if let relationName = userInfo["relation"] as? String {
                        return .relation(table, record, relationName)
                    } else {
                        return .record(table, record)
                    }
                } else {
                    return .table(table)
                }
            } else if let settings = userInfo["setting"] as? Bool, settings {
                return .settings
            } /*else if settings = userInfo["logout"] as? Bool, settings {
             return .login // need more things to do like invalidate token etc...
             }*/
            return nil
        }

        static func from(_ json: JSON) -> State? {
            if let table = json["table"].string {
                if json["record"].exists() {
                    let record = json["record"].rawValue
                    if let relation = json["relation"].string {
                        return .relation(table, record, relation)
                    }
                    return .record(table, record)
                }
                return .table(table)
            }
             return nil
         }
    }

}

extension ApplicationCoordinator: ApplicationService {

    static var instance: ApplicationCoordinator = ApplicationCoordinator()

    func register<M: Main>(_ main: M) {
        if ApplicationAuthenticate.hasLogin {

        }
    }

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
            logger.warning("Cannot display relation \(relationName) of record \(record) in \(source) ")
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
                    if let destination = viewControllerToPresent as? ListForm {
                        assertionFailure("\(destination) could not be presented. Not implemented")
                        /*let predicatString = "(\(inverseRelationInfo.name) = %@)"

                        if let relationFormat = relationInfoUI.relationFormat,
                            !relationFormat.isEmpty,
                            let record = recordSearch,
                            let tableInfo = recordSearch?.tableInfo,
                            let formatter = RecordFormatter(format: relationFormat, tableInfo: tableInfo) {
                            previousTitle = formatter.format(record)


                            destination.formContext = FormContext(predicate: NSPredicate(format: predicatString, recordID),
                                                                  actionContext: source.actionContext(),
                                                                  previousTitle: previousTitle,
                                                                  relationName: relationOriginalName,
                                                                  inverseRelationName: inverseRelationInfo.originalName)
                        }*/

                    } else {
                        logger.warning("Failed to transition to relation \(relationName)")
                        completion(false)
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

    public static func open(_ state: State, completion: @escaping (Bool) -> Void) {
        switch state {
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
