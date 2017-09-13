//
//  Temp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// A temp file allow fast cocoapod developement allowing to inject code in dev pods when new files must be created

extension UITextInput {

    public var cursorPosition: Int? {
        get {
            if let selectedRange = self.selectedTextRange {
                let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
                return cursorPosition
            }
            return nil
        }
        set {
            if let newValue = newValue {
                if let newPosition = self.position(from: self.beginningOfDocument, offset: newValue) {
                    self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
                }
            } else {
                // remove
            }
        }
    }

}
extension RawRepresentable where RawValue == Int {

    public var indexSet: IndexSet {
        return IndexSet(integer: rawValue)
    }

    public static func == (section: Self, value: Int) -> Bool {
        return section.rawValue == value
    }

}

extension UITableViewController {

    public func reload<S: RawRepresentable>(section: S) where S.RawValue == Int {
        assert(Thread.isMainThread)
        self.tableView.reloadSections(section.indexSet, with: .none)
    }

    
    public func assertTableViewAttached() {
        assert(tableView.dataSource === self)
        assert(tableView.delegate === self)
    }
}

/// Protocol for UI element associated with an interface
public protocol UINibable {
    /// The name of the nib to be loaded to instantiate the view.
    var nibName: String? { get }
    /// The bundle from which to load the nib.
    var nibBundle: Bundle? { get }
}

extension UINibable {

    /// Create an `UINib` using the `nibName` and `nibBundle`
    public var nib: UINib? {
        guard let nibName = self.nibName else {
            return nil
        }
        return UINib(nibName: nibName, bundle: nibBundle)
    }

    public var nibBundle: Bundle? {
        return nil // by default
    }

}

extension UINibable where Self: UIView {
    public var nibName: String? {
        return self.className
    }
}

extension UIViewController: UINibable {}

extension UINibable {

    public func registerHeaderFooter(to tableView: UITableView, reuseIdentifier: String) {
        if let nib = self.nib {
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
    }
}


extension UITableView {
    // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
    open func dequeueReusableCell<T: ReusableView>(_: T.Type) -> T? {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T
    }

    // like dequeueReusableCellWithIdentifier:, but for headers/footers
    open func dequeueReusableHeaderFooterView<T: ReusableView>(_: T.Type) -> T?  {
        return dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T
    }

    // Instances returned from the new dequeue method will also be properly sized when they are returned.
    
    open func registerCell<T: ReusableView>(_ nib: UINib?, for: T.Type) {
        self.register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }

    open func registerHeaderFooter<T: ReusableView>(_ nib: UINib?, for: T.Type) {
        self.register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
    
    open func registerHeaderFooter<T>(_ view: T) where T: ReusableView, T: UINibable {
        if let nib = view.nib {
            self.register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        }
    }
}

public protocol ReusableView {
    static var reuseIdentifier: String { get }
}

public extension ReusableView {
    public static var reuseIdentifier: String {
        let className = String(describing: self)
        return "\(className)"
    }
}

/*
 class UserDefaultsListener: NSObject {
 
 let pref: UserDefaults
 let key: String
 let observer: (UserDefaults, String) -> Void
 
 init(default pref: UserDefaults = UserDefaults.standard, forKeyPath key: String, observer: @escaping (UserDefaults, String) -> Void) {
 self.pref = pref
 self.key = key
 self.observer = observer
 super.init()
 
 pref.addObserver(self, forKeyPath: key, options: [.new, .old, .prior, .initial], context: nil)
 }
 
 deinit {
 pref.removeObserver(self, forKeyPath: key)
 }
 
 override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
 if keyPath == self.key {
 observer(pref, key)
 }
 }
 }*/

extension UserDefaults {
    
    public func observe(forKeyPath key: String, _ observer: @escaping (UserDefaults, String) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: self, queue: nil) { notification in
            if let pref = notification.object as? UserDefaults, pref == self {
                observer(self, key)
            }
        }
    }
}
