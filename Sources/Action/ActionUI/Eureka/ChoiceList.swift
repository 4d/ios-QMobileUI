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

    /// Create a choice list frm decoded data and parameter type.
    init?(choiceList: AnyCodable, type: ActionParameterType) {
        if let choiceArray = choiceList.value as? [Any] {
            options = choiceArray.enumerated().map { (arg) -> ChoiceListItem in
                let (key, value) = arg
                if let entry = value as? [String: Any], let key = entry["key"], let value = entry["value"] {
                    if let string = key as? String {
                        switch type {
                        case .bool, .boolean:
                            return ChoiceListItem(key: string.boolValue /* "1" or "0" */ || string == "true", value: value)
                        case .integer:
                            return ChoiceListItem(key: Int(string) as Any, value: value)
                        case .number:
                            return ChoiceListItem(key: Double(string) as Any, value: value)
                        default:
                            return ChoiceListItem(key: key, value: value)
                        }
                    } else {
                        return ChoiceListItem(key: key, value: value)
                    }
                } else {
                    switch type {
                    case .bool, .boolean:
                        return ChoiceListItem(key: key == 1, value: value)
                    case .string:
                        return ChoiceListItem(key: "\(key)", value: value)
                    case .number:
                        return ChoiceListItem(key: Double(key), value: value)
                    default:
                        return ChoiceListItem(key: key, value: value)
                    }
                }
            }
        } else if let choiceDictionary = choiceList.value as? [AnyHashable: Any] {
            if ActionManager.customFormat, let dataClass = choiceDictionary["dataClass"] as? String ?? choiceDictionary["table"] as? String,
               let dataFieldOriginal = choiceDictionary["field"] as? String,
               let tableInfo = DataStoreFactory.dataStore.tableInfo(forOriginalName: dataClass),
               let dataField = tableInfo.fieldInfo(forOriginalName: dataFieldOriginal)?.name {

                var recordFormatter: RecordFormatter? = nil
                if let dataFormat = choiceDictionary["format"] as? String {
                    recordFormatter = RecordFormatter(format: dataFormat, tableInfo: tableInfo)
                }
                
                var sortDescriptors = [NSSortDescriptor(key: dataField, ascending: true)]
                if let dataSort = choiceDictionary["sort"] as? String {
                    // XXX maybe split if contains / like sort in table, maybe factorize code to parse string to nssortdescriptos
                    sortDescriptors = [NSSortDescriptor(key: dataSort, ascending: true)]
                }
 
                let fetchedRequest = DataStoreFactory.dataStore.fetchRequest(tableName: dataClass, sortDescriptors: sortDescriptors)
                var records: [Record] = []
                var optionsFromRecords: [ChoiceListItem] = []
                _ = DataStoreFactory.dataStore.perform(.background, wait: true, blockName: "ChoiceList") { context in
                    records = (try? context.fetch(fetchedRequest)) ?? []
                    
                    optionsFromRecords = records.compactMap { record in
                        guard let key = record[dataField] else { return nil }
                        // XXX maybe see if need to convert key to specific type
                        if let recordFormatter = recordFormatter {
                            return ChoiceListItem(key: key, value: recordFormatter.format(record))
                        } else {
                            return ChoiceListItem(key: key, value: "\(key)")
                        }
                    }
                }
                options = optionsFromRecords
            } else {
                options = choiceDictionary.map { (arg) -> ChoiceListItem in
                    let (key, value) = arg
                    
                    if let string = key as? String {
                        switch type {
                        case .bool, .boolean:
                            return ChoiceListItem(key: string.boolValue /* "1" or "0" */ || string == "true", value: value)
                        case .integer:
                            return ChoiceListItem(key: Int(string) as Any, value: value)
                        case .number:
                            return ChoiceListItem(key: Double(string) as Any, value: value)
                        default:
                            return ChoiceListItem(key: key, value: value)
                        }
                    } else {
                        // must not occurs but in case...
                        assertionFailure("key for action parameter choice is not a string \(key)")
                        return ChoiceListItem(key: key, value: value)
                    }
                }
            }
        } else {
            options = []
            return nil
        }
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
