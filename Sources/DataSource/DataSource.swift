//
//  DataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileDataStore
import XCGLogger
import ValueTransformerKit

/// Class to present data to table or collection views
open class DataSource: NSObject, TableOwner {

    // MARK: - data
    /// The controller to fetch data
    open var fetchedResultsController: FetchedResultsController

    /// Default cell identifier for cell reuse.
    open /*private(set)*/ var cellIdentifier: String

    open weak var delegate: DataSourceDelegate?
    open var showSectionBar: Bool = false
    open var sectionFieldFormatter: String? {
        didSet {
            if let sectionFieldFormatter = sectionFieldFormatter, !sectionFieldFormatter.isEmpty {
                if let valueTransformer = self.valueTransformer(forName: sectionFieldFormatter) {
                    sectionFieldValueFormatter = valueTransformer
                } else if let transformer = ValueTransformer(forName: NSValueTransformerName(sectionFieldFormatter)) {
                    sectionFieldValueFormatter = transformer // have register a transformer could help to replace a big switch...
                } else if sectionFieldFormatter.hasPrefix("localizedText,") {
                    sectionFieldValueFormatter = StringPrefixer(prefix: sectionFieldFormatter.replacingOccurrences(of: "localizedText,", with: "")) + StringTransformers.localized(Bundle.uiBinding, String.localizedBindingTableName)

                } else if sectionFieldFormatter.hasPrefix("imageNamed,") {
                    sectionFieldValueFormatter = StringPrefixer(prefix: sectionFieldFormatter.replacingOccurrences(of: "imageNamed,", with: ""))
                } else if sectionFieldFormatter.hasPrefix("systemImageNamed,") {
                    sectionFieldValueFormatter = StringPrefixer(prefix: sectionFieldFormatter.replacingOccurrences(of: "systemImageNamed,", with: ""))
                }
            } else {
                sectionFieldValueFormatter = nil
            }
        }
    }
    var sectionFieldValueFormatter: ValueTransformer?

    /// Initialize data source for a collection view.
    public init(fetchedResultsController: FetchedResultsController, cellIdentifier: String? = nil) {
       // self.viewType = viewType
        self.fetchedResultsController = fetchedResultsController
        self.cellIdentifier = cellIdentifier ?? fetchedResultsController.tableName
        super.init()

        self.fetchedResultsController.delegate = self
    }

    deinit {
        self.fetchedResultsController.delegate = nil
    }

    // MARK: - Variables and shortcut on internal fetchedResultsController

    /// DataSource predicate
    open var predicate: NSPredicate? {
        get {
            return self.fetchedResultsController.fetchRequest.predicate
        }
        set {
            var fetchRequest = self.fetchedResultsController.fetchRequest
            let oldPredicate = fetchRequest.predicate
            if let newValue = newValue {
                if let contextPredicate = contextPredicate {
                    fetchRequest.predicate = newValue && contextPredicate
                } else {
                    fetchRequest.predicate = newValue
                }
            } else {
                fetchRequest.predicate = contextPredicate
            }

            if oldPredicate != newValue {
                self.refresh()
            } else {
                onWillFetch()
            }
        }
    }

    open var contextPredicate: NSPredicate? {
        didSet {
           let predicate = self.predicate
           self.predicate = predicate // force create predicate XXX crappy, try to have an other value
        }
    }

    /// DataSource sortDescriptors
    public var sortDescriptors: [NSSortDescriptor]? {
        get {
            return self.fetchedResultsController.fetchRequest.sortDescriptors
        }
        set {
            var fetchRequest = self.fetchedResultsController.fetchRequest
            fetchRequest.sortDescriptors = newValue

            self.refresh()
        }
    }

    public var sectionNameKeyPath: String? {
        return self.fetchedResultsController.sectionNameKeyPath
    }

    public var count: Int {
        return self.fetchedResultsController.numberOfRecords
    }

    public var numberOfSections: Int {
        return self.fetchedResultsController.numberOfSections
    }

    public func valid(sectionIndex index: Int) -> Bool {
        return index < self.numberOfSections
    }

    public var isEmpty: Bool {
        return self.fetchedResultsController.isEmpty
    }

    public var fetchedRecords: [Record] {
        return self.fetchedResultsController.fetchedRecords ?? [Record]()
    }

    public func record(at indexPath: IndexPath) -> Record? {
        return self.fetchedResultsController.record(at: indexPath)
    }

    public var tableName: String {
        return self.fetchedResultsController.tableName
    }

    // MARK: source functions

    /// Do a fetch
    public func performFetch() {
        do {
            onWillFetch()
            try self.fetchedResultsController.performFetch()
        } catch {
            logger.error("Error fetching records \(error)")
        }
    }

    public func refresh() {
        self.performFetch()

        // CLEAN maybe not necessary if fetch notify table to reload
        reloadData()
    }

    // MARK: to override
    func failOverride(_ function: String = #function) {
        #if DEBUG
        assertionFailure("\(function) not implemented")
        #else
        logger.error("\(function) missing implementation. please advice SDK owner.")
        #endif
    }
    func reloadData() {
       failOverride()
    }
    /// Notify view of update beginning.
    func beginUpdates() {
        failOverride()
    }

    /// Notify view of update ends.
    func endUpdates() {
        failOverride()
    }

    public func sectionChange(at sectionIndex: Int, for type: FetchedResultsChangeType) {
        failOverride()
    }

    public func onWillFetch() {
        failOverride()
    }

    /// Reload cells at specific index path
    public func reloadCells(at indexPaths: [IndexPath]) {
        failOverride()
    }

    /// Notify view about change.
    func didChangeRecord(_ record: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, _ newIndexPath: IndexPath?) {
        failOverride()
    }

    func valueTransformer(forName name: String) -> ValueTransformer? {
        guard let resersableValueTransformer = self.resersableValueTransformer(forName: name) else {
            return nil
        }
        var transformer = resersableValueTransformer.transformer

        // transform string to date or number before apply transformation to string format (infact, core data already apply a simple to string to data)
        if resersableValueTransformer is DateTransformers {
            transformer = StringToDateDateTransformer(formatter: DateFormatter.reverseToStringformatter) + transformer
        } else if resersableValueTransformer is TimeTransformers || resersableValueTransformer is NumberTransformers {
            transformer = NumberTransformers.formatter(.none).transformer.reverse + transformer
        }

        return transformer
    }

    func resersableValueTransformer(forName name: String) -> ResersableValueTransformerType? {
        switch name.lowercased() {
        case "mediumdate":
            return DateTransformers.medium
        case "longdate":
            return DateTransformers.long
        case "shortdate":
            return DateTransformers.short
        case "fulldate":
            return DateTransformers.full
        case "date":
            return DateTransformers.rfc822
        case "longtime":
            return TimeTransformers.long
        case "fulltime":
            return TimeTransformers.full
        case "mediumtime":
            return TimeTransformers.medium
        case "shorttime":
            return TimeTransformers.short
        case "duration":
            return TimeTransformers.short // XXX not implemented
        case "decimal":
            return NumberTransformers.numberStyle(.decimal)
        case "percent":
            return NumberTransformers.numberStyle(.percent)
        case "scientific":
            return NumberTransformers.numberStyle(.scientific)
        case "spellout":
            return NumberTransformers.numberStyle(.spellOut)
        case "ordinal":
            return NumberTransformers.numberStyle(.ordinal)
        case "integer":
            return NumberTransformers.numberStyle(.none)
        case "currencydollar":
            return NumberTransformers.formatter(.currencyDollar)
        case "currencyeuro":
            return NumberTransformers.formatter(.currencyEuro)
        case "currencyyen":
            return NumberTransformers.formatter(.currencyYen)
        case "currencylivresterling":
            return NumberTransformers.formatter(.currencyLivreSterling)
        default:
            return nil
        }
    }
}

extension DateFormatter {

    // date formatter which return date from string producted when doing String(describing: date)
    fileprivate static var reverseToStringformatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }

}
