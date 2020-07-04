//
//  Binder.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Prephirences

/// Object to remap KVC binding
open class Binder: NSObject {

    // MARK: attribute
    weak open var view: Binded?

    fileprivate static let recordVarKey = "record"

    // cache on record
    @objc dynamic open var record: AnyObject? {
        didSet {
            if /*updateViewOnDidSet &&*/ (self.table != nil) {
                updateView()
            }
        }
    }

    fileprivate static let tableVarKey = "table"
    @objc dynamic open var table: DataSourceEntry? {
        willSet {
            // table?.indexPathObservers.remove(at: self)
        }
        didSet {
            record = table?.record
            table?.add(indexPathObserver: self)
        }
    }

    fileprivate static let settingsKey = "settings"
    open var settings: PreferencesType? {
        get {
            return Prephirences.sharedInstance
        }
        set {
            if let pref = newValue {
                Prephirences.sharedInstance = pref
            }
        }
    }
    private static let reservedKey = [recordVarKey, tableVarKey, settingsKey]

    // entry created by undefined key set to this object
    fileprivate var entries = [KeyPathEntry]()
    fileprivate var keyPaths = [String]()

    // MARK: init
    public init(view: Binded) {
        self.view = view
    }

    // MARK: override KVC codding
    open override func value(forUndefinedKey key: String) -> Any? {
        #if !TARGET_INTERFACE_BUILDER
            logger.debug("Bind \(key)")
        #endif

        // record undefined for setValue
        self.keyPaths.append(key)
        return self
    }

    open override func value(forKey key: String) -> Any? {
        if [Binder.recordVarKey, Binder.tableVarKey, Binder.settingsKey].contains(key) {
            self.keyPaths.append(key)
            return self
        } else {
            return super.value(forKey: key)
        }
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if let viewKey = value as? String {
            #if TARGET_INTERFACE_BUILDER
            if var attributable = view as? IBAttributable {
                if attributable.ibAttritutable == nil {
                    attributable.ibAttritutable = "[]\(key)"
                }
            }
            #else
            createEntry(for: viewKey, key: key)
            #endif
        }
    }

    fileprivate func createEntry(for viewKey: String, key: String) {
        if let view = self.view {
            var currentRecordView: Binded? = view

            var entryKeyPathArray = [String]()

            // Look up potential other view hierarchy using path component parsing
            var localVarKey: String?

            let keyPaths = self.keyPaths
            for pathComponent in keyPaths {
                if Binder.reservedKey.contains(pathComponent) {
                    localVarKey = pathComponent
                } else if localVarKey == nil {
                    currentRecordView = self.binded(for: currentRecordView, pathComponent: pathComponent)
                } else {
                    entryKeyPathArray.append(pathComponent)
                }
            }
            if !keyPaths.isEmpty && localVarKey != nil {
                currentRecordView = currentRecordView?.bindedRoot
            }
            self.resetKeyPath()

            entryKeyPathArray.append(key)

            // create the binder entry
            var entryKeyPath = entryKeyPathArray.joined(separator: ".")
            /// trim entry key path
            var entryKeyPathComponents = ArraySlice(entryKeyPath.components(separatedBy: ","))
            if let firstComponent = entryKeyPathComponents.popFirst() {
                entryKeyPath = firstComponent
            }
            /// trim viewKey key path
            var viewKey = viewKey
            var viewKeyComponents = ArraySlice(viewKey.components(separatedBy: ","))
            if let firstComponent = viewKeyComponents.popFirst() {
                viewKey = firstComponent
            }

            /// Create the entry
            let newEntry = KeyPathEntry(keyPath: entryKeyPath, viewKey: viewKey.viewKeyCased, view: self.view, localVarKey: localVarKey)

            // Check if additional information has been added to create a transformer in entry
            newEntry.transformer = transformer(for: Array(entryKeyPathComponents + viewKeyComponents), viewKey: viewKey.viewKeyCased)

            // Add the entry to the view
            if let currentRecordView = currentRecordView {
                // Just to check if there is some issue, log information
                for entry in entries {
                    if entry.keyPath == newEntry.keyPath {
                        logger.warning("Redundant binding with key \(newEntry.keyPath) on view \(currentRecordView). Please remove it from storyboard.")
                        return // already set
                    } else if newEntry.keyPath.contains(entry.keyPath) {
                        logger.debug("two binding have similar key. new: \(newEntry.keyPath), old: \(entry.keyPath)")
                    } else if entry.keyPath.contains(newEntry.keyPath) {
                        logger.debug("two binding have similar key. new: \(newEntry.keyPath), old: \(entry.keyPath)")
                    }
                }
                let bindTo = currentRecordView.bindTo
                // Append the new entry
                bindTo.entries.append(newEntry)
                // if record already there, update view now for this entry
                bindTo.updateView(for: newEntry) // XXX check if call is necessary or didSet on currentRecords is enought, maybe check status loaded
            }
        }
    }

    fileprivate func transformer(for components: [String], viewKey: String) -> ValueTransformer? {
        if let component  = components.first {
            if let transformer = ValueTransformer(forName: NSValueTransformerName(component)) {
                return transformer
            }
            let name = NSValueTransformerName(viewKey + component)
            if let transformer = ValueTransformer(forName: name) {
                return transformer
            }

            var transformer: ValueTransformer?
            switch viewKey {
            case "localizedText", "imageNamed":
                transformer = StringPrefixer(prefix: component)
                logger.debug("Undefined transformer \(component) or \(viewKey),\(component). Will be created.")
            default:
                transformer = nil
            }
            if let transformer = transformer {
                ValueTransformer.setValueTransformer(transformer, forName: name)
            }
            return transformer
        }
        return nil
    }
    /*open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
     if let context = context {
            // XXX check safety
            let entry = Unmanaged<KeyPathEntry>.fromOpaque(context).takeUnretainedValue()
            self.updateView(for: entry)
        }
    }*/

    // MARK: private

    internal func resetKeyPath() {
        self.keyPaths.removeAll()
    }

    /// Update all binding views.
    internal func updateView() {
        for entry in self.entries {
            self.updateView(for: entry)
        }
    }

    ///fileprivate var updateViewOnDidSet = true

    /*
    internal func beginUpdateView() {
        updateViewOnDidSet = false
    }
    
    internal func endUpdateView() {
        if !updateViewOnDidSet {
            self.updateView()
            updateViewOnDidSet = true
        }
    }
   */

    /// If put an image or data into restImage, manage it
    fileprivate func fix(key: inout String, accordingTo extractedValue: Any?) {
        if key == "restImage" { // for test purpose, fix type
            //logger.debug("The view '\(view)'  \(key). \(String(unwrappedDescrib: extractedValue))")
            if extractedValue is Data {
                key = "imageData"
            } else if extractedValue is UIImage {
                key = "image"
            }
        }
    }

    fileprivate func updateView(for entry: KeyPathEntry) {
        guard let view = entry.binded else { return }

        // Get the value according to key
        var extractedValue: Any?
        switch entry.localVarKey ?? "" {
        case Binder.recordVarKey:
            extractedValue = self.record?.value(forKeyPath: entry.keyPath)
        case Binder.settingsKey:
            extractedValue = self.settings?[entry.keyPath]
        case Binder.tableVarKey:
            extractedValue = self.table?.value(forKeyPath: entry.keyPath)
        default:
            extractedValue = nil
        }
        // Transform value if a transformer is defined
        if let transformer = entry.transformer {
            extractedValue = transformer.transformedValue(extractedValue)
        }

        // Get the view key and check it
        var key = entry.viewKey
        assert(!view.hasProperty(name: key), "The view '\(view)' has no property \(key). Check right part of binding.") // maybe inherited field could not be checked, and assert must be modified
        fix(key: &key, accordingTo: extractedValue)

        // Set value to view
        view.setProperty(name: key, value: extractedValue)
    }

    // MARK: parsers
    // Find view according to pathComponent in view hierarchy
    fileprivate func binded(for view: Binded?, pathComponent: String) -> Binded? {
        var result: Binded?

        // OPTI: could put parsers in dico if a parser match pathComponent only on function attribute
        for parser in Binder.parsers {
            result = parser.parse(keyPathComponent: pathComponent, for: view)
            if result != nil {
                return result
            }
        }
        if pathComponent == "settings" {
            return view
        }
        assert(result != nil, "Unable to find view \(pathComponent)")
        return result
    }
    // List of function parser
    fileprivate static let functionOperator = "@"
    fileprivate static let parsers: [KeyPathParser] = [

        // XXX simply, all now use string, no need to mayke this parser

        // ASK if operator for function @ could be replaced by an another one
        KeyPathParser(function: "\(functionOperator)superview") { view, _ in
            guard let view = view else { return nil }
            if let theView = view.getPropertyValue(name: "superview") as? Binded {
                return theView
            }
            logger.warning("\(String(describing: view)) has no superview")
            return nil
        }
        ,
        KeyPathParser(function: "\(functionOperator)root") { view, _ in
            guard let view = view else { return nil }
            if let theView = view.getPropertyValue(name: "root") as? Binded {
                return theView
            }
            logger.warning("\(view) has no root view")
            return nil
        }
        ,
        KeyPathParser(function: "\(functionOperator)cell") { view, _ in
            guard let view = view else {
                return nil
            }
            if let theView = view.getPropertyValue(name: "cell") as? Binded {
                return theView
            }
            logger.warning("\(view) has no cell view")
            return nil
        },
        // @subviews[<index>]
        KeyPathParser.intParser(function: "\(functionOperator)subviews") { view, integer in
            guard let view = view else {
                return nil
            }
            if let index = integer, let subviews = view.getPropertyValue(name: "subviews") as? [Binded] {
                if index >= 0 && index < subviews.count {
                    let theView = subviews[index]
                    return theView
                }
                logger.warning("\(view) has no sub cell view at index \(index)")
            }
            return nil
        }
    ]
    // CustomStringConvertible

    open override var description: String {
        return "\(super.description), view: \(String(describing: self.view)), record: \(String(describing: self.record)), entries: \(self.entries)"
    }

}

// MARK: KeyPathEntry

private class KeyPathEntry {

    // the key path to get data from binded object
    var keyPath: String
    // The key to bind om view (could be text, value, url for image, or custom one)
    var viewKey: String
    // the binded element
    weak var binded: Binded?
    // the bintTo attribute to bind (record, table) -> XXX add a closure instead ?
    var localVarKey: String?

    var transformer: ValueTransformer?

    init(keyPath: String, viewKey: String, view: Binded?, localVarKey: String?) {
        self.keyPath = keyPath
        self.viewKey = viewKey
        self.binded = view
        self.localVarKey = localVarKey

        if viewKey.contains(",") {
            let split = viewKey.components(separatedBy: ",")
            self.viewKey = split.first ?? viewKey
            if let transformerName = split[safe: 1] {
                transformer = ValueTransformer(forName: NSValueTransformerName(transformerName))
            }
        }
    }
}

// MARK: KeyPathParser
private class KeyPathParser {

    var function: String
    var block: (_ view: Binded?, _ keyPathComponent: String) -> Binded?

    init(function: String, block :@escaping (_ view: Binded?, _ keyPathComponent: String) -> Binded?) {
        self.function = function
        self.block = block
    }

    func parse(keyPathComponent: String, for view: Binded?) -> Binded? {
        // Check if must use this parser
        if keyPathComponent.hasPrefix(self.function) {
            return self.block(view, keyPathComponent)
        }
        return nil
    }

    // allow to extract int argument from <function>[<arg>]
    static func intParser(function: String, block :@escaping (_ view: Binded?, _ parameter: Int?) -> Binded?) -> KeyPathParser {
        return KeyPathParser(function: function) { view, keyPathComponent in
            let result = scan(keyPathComponent: keyPathComponent, function: function)
            return block(view, result)
        }
    }

    static func scan(keyPathComponent: String, function: String) -> Int? {
        let scanner = Scanner(string: keyPathComponent)
        guard scanner.scanString(function) != nil else { return nil }
        guard scanner.scanString("[") != nil else { return nil }
        if let result = scanner.scanInt() {
            return result
        }
        // scanner.scanString("]")
        return nil
    }
    // XXX do it for string if <function>[<arg>] zith string arg

}

private extension Array {
    var second: Element? { return self.count > 1 ? self[1] : nil }
}

// MARK: observer change on table
extension Binder: IndexPathObserver {

    public func willChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?) {}
    public func didChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?) {
        record = table?.record
    }
}
