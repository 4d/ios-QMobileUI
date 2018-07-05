//
//  Binder.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Prephirences

public protocol Binded: NSObjectProtocol {
    /// A Binded object must have a Binder.
    var bindTo: Binder { get }

    /// Return the real element which contain all information. A root one.
    var bindedRoot: Binded { get }

    // MARK: properties
    /// `true` if a property exist
    func hasProperty(name: String) -> Bool
    /// list of properties
    var propertyNames: [String] { get }
    /// set value for a property using its name
    func setProperty(name: String, value: Any?)
    /// get property value
    func getPropertyValue(name: String) -> Any?
}

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
        if let string = value as? String {
            let viewKey = string.viewKeyCased
            #if TARGET_INTERFACE_BUILDER
                if ui.ibAttritutable == nil {
                    if let attributable = binded as? IBAttributable {
                        ui.ibAttritutable = "[]\(key)"
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
            var localVarKey: String? = nil

            for pathComponent in self.keyPaths {
                if [Binder.recordVarKey, Binder.tableVarKey, Binder.settingsKey].contains(pathComponent) {
                    localVarKey = pathComponent
                } else {
                    if localVarKey == nil {
                        currentRecordView = self.binded(for: currentRecordView, pathComponent: pathComponent)
                    } else {
                        entryKeyPathArray.append(pathComponent)
                    }
                }
            }
            if self.keyPaths.count == 1 && localVarKey != nil {
                currentRecordView = currentRecordView?.bindedRoot
            }
            self.resetKeyPath()

            entryKeyPathArray.append(key)

            // create the binder entry
            var entryKeyPath = entryKeyPathArray.joined(separator: ".")

            let temp = entryKeyPath.components(separatedBy: ",")
            if let first = temp.first {
                entryKeyPath = first
            }
            let newEntry = KeyPathEntry(keyPath: entryKeyPath, viewKey: viewKey, view: self.view, localVarKey: localVarKey)
            if let second = temp.second {
                newEntry.transformer = ValueTransformer(forName: NSValueTransformerName(second))
            }

            if let bindTo = currentRecordView?.bindTo {

                for entry in entries {
                    if entry.keyPath == newEntry.keyPath {
                        logger.warning("Redundant binding with key \(newEntry.keyPath) on view \(String(describing: currentRecordView))")
                        return // already set
                    } else if newEntry.keyPath.contains(entry.keyPath) {
                        logger.debug("two binding have similar key. new: \(newEntry.keyPath), old: \(entry.keyPath)")
                    } else if entry.keyPath.contains(newEntry.keyPath) {
                        logger.debug("two binding have similar key. new: \(newEntry.keyPath), old: \(entry.keyPath)")
                    }
                }
                bindTo.entries.append(newEntry)
                bindTo.updateView(for: newEntry) // XXX check if call is necessary or didSet on currentRecords is enought, maybe check status loaded
            }
        }
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

    fileprivate func updateView(for entry: KeyPathEntry) {
        // CLEAN factorize code, maybe using closure, KVC will not work using  entry.localVarKey
        if let key = entry.localVarKey, key == Binder.tableVarKey {

            guard let table = self.table else {
                return // maybe ui component loading
            }

            if let view = entry.binded {
                let extractedValue = table.value(forKeyPath: entry.keyPath)
                view.setProperty(name: entry.viewKey, value: extractedValue)
            }
        } else { // record

            if let view = entry.binded {
                var extractedValue: Any? = nil
                switch entry.localVarKey ?? "" {
                case "record":
                    if let record = self.record {
                        extractedValue = record.value(forKeyPath: entry.keyPath)
                    }
                case "settings":
                    extractedValue = self.settings?[entry.keyPath]
                default:
                    extractedValue = nil
                }
                if let transformer = entry.transformer {
                    view.setProperty(name: entry.viewKey, value: transformer.transformedValue(extractedValue))
                } else {
                    var key = entry.viewKey
                    assert(!view.hasProperty(name: key), "The view '\(view)' has no property \(key). Check right part of binding.") // maybe inherited field could not be checked, and assert must be modified
                    //logger.debug("The view '\(view)'  \(key). \(String(unwrappedDescrib: extractedValue))")

                    if key == "restImage" { // for test purpose, fix type
                        if extractedValue is Data {
                            key = "imageData"
                        } else if extractedValue is UIImage {
                            key = "image"
                        }
                    }
                    view.setProperty(name: key, value: extractedValue)
                }
            }
        }
    }

    // MARK: parsers
    // Find view according to pathComponent in view hierarchy
    fileprivate func binded(for view: Binded?, pathComponent: String) -> Binded? {
        var result: Binded? = nil

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
            var success = true
            var result: Int = 0

            let scanner = Scanner(string: keyPathComponent)
            success = scanner.scanString(function, into: nil) && success
            success = scanner.scanString("[", into: nil) && success
            success = scanner.scanInt(&result) && success
            success = scanner.scanString("]", into: nil) && success

            return block(view, success ? result : nil)
        }
    }
    // XXX do it for string if <function>[<arg>] zith string arg

}

private extension Array {
    var second: Element? { return self.count > 1 ? self[1] : nil }
}

extension Binded {
   public func hasProperty(name: String) -> Bool {
        for child in Mirror(reflecting: self).children where child.label == name {
            return true
        }
        return false
    }
    public var propertyNames: [String] {
        return Mirror(reflecting: self).children.compactMap { $0.label }
    }
}

extension UIView: Binded {
    public func setProperty(name: String, value: Any?) {
        self.setValue(value, forKey: name)
    }

    public func getPropertyValue(name: String) -> Any? {
        // add some mapping
        switch name {
        case "root": return rootView
        case "cell": return parentCellView
        default: return value(forKey: name)
        }
    }

    public var bindedRoot: Binded {
        // what we want : if dynamic table, the cellview must be selected, otherwise the root view. And root view must not be a cell..

        // CLEAN here a tricky way to select cellview or rootview, very very dirty code
        // maybe we could check table type, or add a protocol or a boolean(at creation, not runtime) to a view to select it
        if let cellView = self.parentCellView {
            if cellView.parentViewSource is DataSource { // List form, keep cell data
                if let binded = cellView as? Binded {
                    return binded
                }
            }
            if let rootView = self.rootView {
                return rootView
            }
            if let binded = cellView as? Binded {
                return binded
            }
        }

        if let rootView = self.rootView {
            return rootView
        }
        return self
    }
}
extension UIBarItem: Binded {
    public func setProperty(name: String, value: Any?) {
        self.setValue(value, forKey: name)
    }
    public func getPropertyValue(name: String) -> Any? {
        return value(forKey: name)
    }
    public var bindedRoot: Binded {
        return self
    }
}

// MARK: observer change on table
extension Binder: IndexPathObserver {

    func willChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?) {}
    func didChangeIndexPath(from oldValue: IndexPath?, to newValue: IndexPath?) {
        record = table?.record
    }
}
