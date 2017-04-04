//
//  Binder.swift
//  QMobileUI
//
//  Created by Eric Marchand on 21/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Object to remap KVC binding
open class Binder: NSObject {

    // MARK: attribute
    weak open var view: UIView?

    fileprivate static let recordVarKey = "record"
    open var record: AnyObject? {
        didSet {
            if updateViewOnDidSet && (self.record != nil) /*&& table != nil*/ {
                updateView()
            }
        }
    }
    fileprivate static let tableVarKey = "table"
    dynamic open var table: DataSourceEntry? {
        didSet {
            if updateViewOnDidSet && (self.table != nil) {
                updateView()
            }
        }
    }

    // entry created by undefined key set to this object
    fileprivate var entries = [KeyPathEntry]()
    fileprivate var keyPaths = [String]()

    // MARK: init
    internal init(view: UIView) {
        self.view = view
    }

    // MARK: override KVC codding
    open override func value(forUndefinedKey key: String) -> Any? {
        logger.debug("Bind \(key)")
        // record undefined for setValue
        self.keyPaths.append(key)
        return self
    }

    open override func value(forKey key: String) -> Any? {
        if [Binder.recordVarKey, Binder.tableVarKey].contains(key) {
            self.keyPaths.append(key)
            return self
        } else {
            return super.value(forKey: key)
        }
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if let viewKey = value as? String, let view = self.view {

            var currentRecordView: UIView? = view

            var entryKeyPaths = [String]()

            // Look up potential other view hierarchy using path component parsing
            var localVarKey: String? = nil

            for pathComponent in self.keyPaths {
                if [Binder.recordVarKey, Binder.tableVarKey].contains(pathComponent) {
                    localVarKey = pathComponent
                } else {
                    if localVarKey == nil {
                        currentRecordView = self.view(for: currentRecordView, pathComponent: pathComponent)
                    } else {
                        entryKeyPaths.append(pathComponent)
                    }
                }
            }
            if self.keyPaths.count == 1 && localVarKey != nil {
                // default behaviours?

                // what we want : if dynamic table, the cellview must be selected, otherwise the root view. And root view must not be a cell..

                // CLEAN here a tricky way to select cellview or rootview, very very dirty code
                // maybe we could check table type, or add a protocol or a boolean(at creation, not runtime) to a view to select it
                if let cellView = currentRecordView?.parentCellView {
                    if cellView.parentViewSource is DataSource { // List form, keep cell data
                        currentRecordView = cellView as? UIView
                    }
                    // else take info from root view
                    else if let rootView = currentRecordView?.rootView {
                        currentRecordView = rootView
                    } else {
                        currentRecordView = cellView as? UIView
                    }
                } else if let rootView = currentRecordView?.rootView {
                    currentRecordView = rootView
                }
            }
            self.resetKeyPath()

            entryKeyPaths.append(key)

            // create the binder entry
            let newEntryKeyPath = entryKeyPaths.joined(separator: ".")
            let newEntry = KeyPathEntry(keyPath: newEntryKeyPath, viewKey: viewKey, view: self.view, localVarKey: localVarKey)
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

    fileprivate var updateViewOnDidSet = true

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

            if let view = entry.view {
                let extractedValue = table.value(forKeyPath: entry.keyPath)
                view.setValue(extractedValue, forKey: entry.viewKey)
            }
        } else { // record

            guard let record = self.record else {
                return // maybe ui component loading
            }
            if let view = entry.view {
                let extractedValue = record.value(forKeyPath: entry.keyPath)

                if let transformer = entry.transformer {
                    view.setValue(transformer.transformedValue(extractedValue), forKey: entry.viewKey)
                } else {
                    view.setValue(extractedValue, forKey: entry.viewKey)
                }
            }
        }
    }

    // MARK: parsers
    // Find view according to pathComponent in view hierarchy
    fileprivate func view(for view: UIView?, pathComponent: String) -> UIView? {
        var result: UIView? = nil

        // OPTI: could put parsers in dico if a parser match pathComponent only on function attribute
        for parser in Binder.parsers {
            result = parser.parse(keyPathComponent: pathComponent, for: view)
            if result != nil {
                return result
            }
        }
        assert(result != nil, "Unable to find view \(pathComponent)")
        return result
    }
    // List of function parser
    fileprivate static let functionOperator = "@"
    fileprivate static let parsers: [KeyPathParser] = [

        // ASK if operator for function @ could be replaced by an another one
        KeyPathParser(function: "\(functionOperator)superview") { view, _ in
            guard let view = view else {
                return nil
            }
            if let theView = view.superview {
                return theView
            }
            logger.warning("\(String(describing: view)) has no superview")
            return nil
        }
        ,
        KeyPathParser(function: "\(functionOperator)rootview") { view, _ in
            guard let view = view else {
                return nil
            }
            if let theView = view.rootView {
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
            if let theView = view.parentCellView as? UIView {
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
            if let index = integer {
                let subviews = view.subviews
                if index >= 0 && index < subviews.count {
                    let theView = view.subviews [index]
                    return theView
                }
                logger.warning("\(view) has no sub cell view at index \(index)")
            }
            return nil
        }
    ]
}

extension Binder/*: CustomStringConvertible*/ {

    open override var description: String {
        return "\(super.description), view: \(String(describing: self.view?.description)), record: \(String(describing: self.record)), entries: \(self.entries)"
    }

}

// MARK : KeyPathEntry
fileprivate class KeyPathEntry {

    // the key path to get data from binded object
    var keyPath: String
    // The key to bind om view (could be text, value, url for image, or custom one)
    var viewKey: String
    // the view to bind
    weak var view: UIView?
    // the bintTo attribute to bind (record, table) -> XXX add a closure instead ?
    var localVarKey: String?

   var transformer: ValueTransformer?

    init(keyPath: String, viewKey: String, view: UIView?, localVarKey: String?) {
        self.keyPath = keyPath
        self.viewKey = viewKey
        self.view = view
        self.localVarKey = localVarKey
    }

}

// MARK : KeyPathParser
fileprivate class KeyPathParser {

    var function: String
    var block: (_ view: UIView?, _ keyPathComponent: String) -> UIView?

    init(function: String, block :@escaping (_ view: UIView?, _ keyPathComponent: String) -> UIView?) {
        self.function = function
        self.block = block
    }

    func parse(keyPathComponent: String, for view: UIView?) -> UIView? {
        // Check if must use this parser
        if keyPathComponent.hasPrefix(self.function) {
            return self.block(view, keyPathComponent)
        }
        return nil
    }

    // allow to extract int argument from <function>[<arg>]
    static func intParser(function: String, block :@escaping (_ view: UIView?, _ parameter: Int?) -> UIView?) -> KeyPathParser {

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
