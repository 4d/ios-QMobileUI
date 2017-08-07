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

public func alert(title: String, error: Error) {
    QMobileUI.alert(title: title, error: error)
}

public func alert(title: String, message: String? = nil) {
    QMobileUI.alert(title: title, message: message)
}

public func dataSync() {
    QMobileUI.dataSync()
}

extension UILabel {

    open override var bindTo: Binder {
        return super.bindTo
    }

}
