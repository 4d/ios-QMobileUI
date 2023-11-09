//
//  ChoiceList.swift
//  QMobileUI
//
//  Created by Eric Marchand on 25/06/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import QMobileAPI
import QMobileDataStore
import QMobileDataSync

/// Represent a choice in choice list
struct ChoiceList {

    /// the choice list
    var options: [ChoiceListItem]

    /// Indicate if could search
    var isSearchable: Bool = false

    /// Activate search if there is more items than this value
    static var isSearchableActionCount: Int = 10

    /// Create a choice list frm decoded data and parameter type.
    init?(choiceList: AnyCodable, type: ActionParameterType, context: ActionContext) {
        if let choiceArray = choiceList.value as? [Any] {
            options = choiceArray.enumerated().map { ChoiceListItem(index: $0.0, value: $0.1, type: type) }
            isSearchable = options.count > ChoiceList.isSearchableActionCount
        } else if let choiceDictionary = choiceList.value as? [AnyHashable: Any] {
            if ActionManager.customFormat, let optionsFromDataSource = ChoiceList.fromDataSource(choiceDictionary: choiceDictionary, type: type, context: context) {
                options = optionsFromDataSource
                if let dataSource = choiceDictionary["dataSource"] as? [String: Any], let searchValue = dataSource["search"] as? Bool {
                    isSearchable = searchValue
                } else {
                    isSearchable = options.count > ChoiceList.isSearchableActionCount
                }
            } else {
                options = choiceDictionary.map { ChoiceListItem(key: $0.0, value: $0.1, type: type) }
                isSearchable = options.count > ChoiceList.isSearchableActionCount
            }
        } else {
            options = []
            return nil
        }
    }

    fileprivate static func isSortAscending(_ dataSortObject: [String: Any]) -> Bool {
        return ((dataSortObject["order"] == nil) || (dataSortObject["order"] as? String == "ascending") || (dataSortObject["ascending"] as? Bool ?? false))
            && !(dataSortObject["descending"] as? Bool ?? false)
    }

    /// Create sort descriptors from data source info
    fileprivate static func createSortDescriptor(_ dataSort: Any, _ tableInfo: DataStoreTableInfo) -> [NSSortDescriptor]? {
        var result: [NSSortDescriptor]?
        if let dataSortString = dataSort as? String { // one string with one or many fields, ascending by default
            result = dataSortString.split(separator: ",")
                .compactMap { tableInfo.existingFieldInfo(String($0).trimmed) }
                .map { $0.sortDescriptor(ascending: true) }
        } else if let dataSortObject =  dataSort as? [String: Any],
                let dataSortOriginal = dataSortObject["field"] as? String,
                let dataSortFieldInfo = tableInfo.existingFieldInfo(dataSortOriginal) { // one existing property
            result = [dataSortFieldInfo.sortDescriptor(ascending: isSortAscending(dataSortObject))]
        } else if let dataSortCollection = dataSort as? [[String: Any]] { // a list of property
            result = dataSortCollection.compactMap { dataSortObject in
                if let dataSortOriginal = dataSortObject["field"] as? String,
                   let dataSortFieldInfo = tableInfo.existingFieldInfo(dataSortOriginal) {
                    return dataSortFieldInfo.sortDescriptor(ascending: isSortAscending(dataSortObject))
                }
                return nil
            }
        }
        if result.isEmpty {
            result = nil // empty, is not supported, let caller use a default one
        }
        return result
    }

    /*fileprivate static func searchFields(choiceDictionary: [AnyHashable: Any], type: ActionParameterType) -> [String]? {
        guard let dataSource = choiceDictionary["dataSource"] as? [String: Any] else {
            return nil // no data source defined, skip
        }
        guard dataSource["search"] != nil else {
            return nil
        }
        // search is activated
        if let searchFieldString = dataSource["search"] as? String {
            return searchFieldString.split(separator: ",").map { String($0) }
        } else if let searchFields = dataSource["search"] as? [String] {
            return searchFields
        }
        // else bool compute it:
        
        guard let dataClass = dataSource["dataClass"] as? String ?? dataSource["table"] as? String,
              let dataFieldOriginal = dataSource["field"] as? String,
              let tableInfo = DataStoreFactory.dataStore.tableInfo(forOriginalName: dataClass),
              let dataField = tableInfo.fieldInfo(forOriginalName: dataFieldOriginal)?.name else {
            return nil // no field to search
        }

        // Get from format if any
        if let dataFormat = dataSource["entityFormat"] as? String ?? dataSource["format"] as? String {
            var searchFields = RecordFormatter(format: dataFormat, tableInfo: tableInfo)?.nodes
                .compactMap({$0 as? FieldNodeType})
                .map({$0.fieldName(tableInfo: tableInfo)})
                .filter({!$0.isEmpty}) ?? []
            
            searchFields.append(dataField)
            return searchFields
            
        } else {
            return [dataField]
        }
    }*/

    /// Create choice list from data Source
    fileprivate static func fromDataSource(choiceDictionary: [AnyHashable: Any], type: ActionParameterType, context: ActionContext) -> [ChoiceListItem]? {
        guard let dataSource = choiceDictionary["dataSource"] as? [String: Any] else {
            return nil // no data source defined, skip
        }

        if let dataClass = dataSource["dataClass"] as? String ?? dataSource["table"] as? String,
           let dataFieldOriginal = dataSource["field"] as? String ?? dataSource["key"] as? String ?? dataSource["attribute"] as? String,
           let tableInfo = DataStoreFactory.dataStore.tableInfo(forOriginalName: dataClass),
           let dataField = tableInfo.fieldInfo(forOriginalName: dataFieldOriginal)?.name {
            // Well defined data source from database

            if let currentEntity = dataSource["currentEntity"] as? Bool, currentEntity {
                let fieldValue = context.actionParameterValue(for: dataField)
                if let choiceDictionary = fieldValue as? [AnyHashable: Any] {
                    if let choiceArray = choiceDictionary["choiceList"] as? [Any] {
                        return choiceArray.enumerated().map { ChoiceListItem(index: $0.0, value: $0.1, type: type) }
                    }
                    var choiceDictionary0 = choiceDictionary
                    if let choiceDictionary = choiceDictionary["choiceList"] as? [AnyHashable: Any] {
                        choiceDictionary0 = choiceDictionary
                    }
                    return choiceDictionary0.map { ChoiceListItem(key: $0.0, value: $0.1, type: type) }
                } else if let choiceArray = fieldValue as? [Any] {
                    return choiceArray.enumerated().map { ChoiceListItem(index: $0.0, value: $0.1, type: type) }
                }
                return []
            }

            var recordFormatter: RecordFormatter?
            if let dataFormat = dataSource["entityFormat"] as? String ?? dataSource["format"] as? String {
                recordFormatter = RecordFormatter(format: dataFormat, tableInfo: tableInfo)
            }

            var sortDescriptors = [NSSortDescriptor(key: dataField, ascending: true)]
            if let dataSort = dataSource["sort"], let customSort = createSortDescriptor(dataSort, tableInfo) {
                sortDescriptors = customSort
            }

            var fetchedRequest = DataStoreFactory.dataStore.fetchRequest(tableName: dataClass, sortDescriptors: sortDescriptors)
            if let filter = dataSource["filter"] as? String {
                fetchedRequest.predicate = NSPredicate(format: filter) // must be coredata but if orda? (need a converter)
            } else if let filters = dataSource["filter"] as? [String: Any], let filter = (filters["ios"] ?? filters["iOS"]) as? String {
                fetchedRequest.predicate = NSPredicate(format: filter) // must be coredata
            }
            var records: [Record] = []
            var optionsFromRecords: [ChoiceListItem] = []
            _ = DataStoreFactory.dataStore.perform(.background, wait: true, blockName: "ChoiceList") { context in
                records = (try? context.fetch(fetchedRequest)) ?? []
                // /!\ get record info in data store context, do not move out the code!
                optionsFromRecords = records.compactMap { record in
                    guard let key = record[dataField] else { return nil }
                    // XXX maybe see if need to convert key to specific type
                    if let recordFormatter = recordFormatter {
                        return ChoiceListItem(key: key, value: recordFormatter.format(record), type: type)
                    } else {
                        return ChoiceListItem(key: key, value: "\(key)", type: type)
                    }
                }
            }
            return optionsFromRecords.uniqued()
        }
        // not correct data source defined
        logger.warning("Unknown data source definition \(dataSource)")
        return nil
    }

    /// Get choice list item by key.
    func choice(for key: AnyCodable) -> ChoiceListItem? {
        for option in options where option.key == key {
            return option
        }
        /*if logger.isEnabledFor(level: .debug) {
            logger.debug("Default value \(key) not found in \(options.map { $0.key }) for action parameters")
            logger.verbose("Default value type \(type(of: key.value))")
            logger.verbose("Options types \(options.map { type(of: $0.key) })")
        }*/
        return nil
    }

    var boolOptions: [ChoiceListItem] {
        let result: [ChoiceListItem] = options
        assert(result.count == 2) // maybe if possible reduce to only two options. but cannot do it here...
        return options
    }

}

extension DataStoreTableInfo {
    fileprivate func existingFieldInfo(_ name: String) -> DataStoreFieldInfo? {
        return self.fieldInfo(forOriginalName: name) ?? self.fieldInfo(for: name)
    }
}
