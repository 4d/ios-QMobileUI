//
//  ListForm.swift
//  Invoices
//
//  Created by Eric Marchand on 10/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileUI

// Here temporary code to fix apple bug on @IBDesignable object precompiled in framework

@IBDesignable
class ListFormTable: QMobileUI.ListFormTable {

    @IBInspectable open override var sectionFieldname: String? {
        get {
            return super.sectionFieldname
        }
        set {
            super.sectionFieldname = newValue
        }
    }

    @IBInspectable open override var selectedSegueIdentifier: String {
        get {
            return super.selectedSegueIdentifier
        }
        set {
            super.selectedSegueIdentifier = newValue
        }
    }

    @IBInspectable open override var searchableField: String {
        get {
            return super.searchableField
        }
        set {
            super.searchableField = newValue
        }
    }

    @IBOutlet open override var searchBar: UISearchBar! {
        get {
            return super.searchBar
        }
        set {
            super.searchBar = newValue
        }
    }

    @IBInspectable open override var showSectionBar: Bool {
        get {
            return super.showSectionBar
        }
        set {
            super.showSectionBar = newValue
        }
    }
}

@IBDesignable
class ListFormCollection: QMobileUI.ListFormCollection {

    @IBInspectable open override var sectionFieldname: String? {
        get {
            return super.sectionFieldname
        }
        set {
            super.sectionFieldname = newValue
        }
    }

    @IBInspectable open override var selectedSegueIdentifier: String {
        get {
            return super.selectedSegueIdentifier
        }
        set {
            super.selectedSegueIdentifier = newValue
        }
    }

    @IBInspectable open override var searchableField: String {
        get {
            return super.searchableField
        }
        set {
            super.searchableField = newValue
        }
    }

    @IBOutlet open override var searchBar: UISearchBar! {
        get {
            return super.searchBar
        }
        set {
            super.searchBar = newValue
        }
    }

    @IBInspectable open override var showSectionBar: Bool {
        get {
            return super.showSectionBar
        }
        set {
            super.showSectionBar = newValue
        }
    }

}

@IBDesignable
class DetailsFormBare: QMobileUI.DetailsFormBare {

    @IBInspectable open override var hasSwipeGestureRecognizer: Bool {
        get {
            return super.hasSwipeGestureRecognizer
        }
        set {
            super.hasSwipeGestureRecognizer = newValue
        }
    }

}

@IBDesignable
class DetailsFormTable: QMobileUI.DetailsFormTable {

    @IBInspectable open override var hasSwipeGestureRecognizer: Bool {
        get {
            return super.hasSwipeGestureRecognizer
        }
        set {
            super.hasSwipeGestureRecognizer = newValue
        }
    }

}

func background(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.async(execute: work)
}
func background(_ delay: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.after(delay, execute: work)
}

func foreground(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.async(execute: work)
}

func userInitiated(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.userInitiated.async(execute: work)
}

func userInteractive(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.userInteractive.async(execute: work)
}

public func alert(title: String, error: Swift.Error) {
    QMobileUI.alert(title: title, error: error)
}

public func alert(title: String, message: String? = nil) {
    QMobileUI.alert(title: title, message: message)
}

import QMobileDataSync
import Moya
public func dataSync(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return QMobileUI.dataSync(completionHandler)
}

public func dataReload(_ completionHandler: @escaping QMobileDataSync.DataSync.SyncCompletionHandler) -> Cancellable? {
    return QMobileUI.dataReload(completionHandler)
}

public func dataLastSync() -> Date? {
    return QMobileUI.dataLastSync()
}

extension UILabel {

    open override var bindTo: Binder {
        return super.bindTo
    }

}
