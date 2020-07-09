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

import XCGLogger
import Prephirences
import FileKit
import ZIPFoundation

class ApplicationCoordinator: NSObject {}

extension ApplicationCoordinator: ApplicationService {

    static var instance: ApplicationCoordinator = ApplicationCoordinator()

    func register<M: Main>(_ main: M) {

        if ApplicationAuthenticate.hasLogin {

        }
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
    static func transition<S: ListForm & UIViewController, D: ListForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI) {
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

    /// Transition for N->1 relation from ListForm
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D, relationInfoUI: RelationInfoUI) {
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

    /// Transition to details
    static func transition<S: ListForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, at indexPath: IndexPath, to destination: D) {
        // create a new entry to bind
        guard let entry = source.dataSource?.entry() else { return }
        entry.indexPath = indexPath
        // pass to view controllers and views
        destination.prepare(with: entry)

        // listen to index path change, to scroll table to new selected record
        entry.add(indexPathObserver: source)
    }

    /// Transition N->1 relation from DetailForm
    static func transition<S: DetailsForm & UIViewController, D: DetailsForm & UIViewController>(from source: S, to destination: D, relationInfoUI: RelationInfoUI) {
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
